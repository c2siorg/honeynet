"""
Honeynet IP Enrichment Lambda
==============================
Triggered by S3 PutObject on the raw log sink bucket.
For each Cowrie JSON log event:
  1. Parses the attacker's source IP
  2. Queries AbuseIPDB for threat score, country, ISP
     — with in-memory caching to avoid rate limit exhaustion
     — with explicit HTTP 429 handling for graceful degradation
  3. Writes enriched record to the enriched-logs S3 bucket

AbuseIPDB free tier: 1,000 req/day
A busy honeypot gets 5,000+ attempts/day — caching is non-negotiable.
"""

import json
import os
import gzip
import urllib.request
import urllib.error
import boto3
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
secrets = boto3.client("secretsmanager")

ENRICHED_BUCKET = os.environ["ENRICHED_BUCKET"]
SECRET_NAME = os.environ["SECRET_NAME"]

# ------------------------------------------------------------------
# Module-level caches — persist across warm Lambda invocations
# This is the critical fix for AbuseIPDB rate limit exhaustion.
# A busy honeypot can see the same IP thousands of times per day.
# ------------------------------------------------------------------
_api_key_cache = None
_ip_cache = {}          # { ip: enrichment_dict }
_rate_limited = False   # If we hit 429, stop calling API for this container lifetime


def get_api_key() -> str:
    """Fetch AbuseIPDB key from Secrets Manager (cached per Lambda container)."""
    global _api_key_cache
    if _api_key_cache:
        return _api_key_cache
    response = secrets.get_secret_value(SecretId=SECRET_NAME)
    _api_key_cache = response["SecretString"].strip()
    return _api_key_cache


def query_abuseipdb(ip: str, api_key: str) -> dict:
    """
    Query AbuseIPDB v2 API for IP reputation data.

    Handles:
    - HTTP 429: sets global rate_limited flag, stops further calls this session
    - Any other failure: returns safe defaults, log still stored unenriched
    - Results cached in _ip_cache to avoid duplicate API calls
    """
    global _rate_limited

    # Check cache first — same IP seen multiple times costs only 1 API call
    if ip in _ip_cache:
        logger.info(f"Cache hit for {ip}")
        return _ip_cache[ip]

    # If we already hit rate limit this container session, skip API call
    if _rate_limited:
        logger.warning(f"Rate limited — skipping AbuseIPDB lookup for {ip}")
        return _default_enrichment(rate_limited=True)

    url = f"https://api.abuseipdb.com/api/v2/check?ipAddress={ip}&maxAgeInDays=90"
    req = urllib.request.Request(
        url,
        headers={
            "Key": api_key,
            "Accept": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode())["data"]
            result = {
                "abuse_score":    data.get("abuseConfidenceScore", 0),
                "country_code":   data.get("countryCode", "UNKNOWN"),
                "isp":            data.get("isp", "UNKNOWN"),
                "domain":         data.get("domain", "UNKNOWN"),
                "is_tor":         data.get("isTor", False),
                "total_reports":  data.get("totalReports", 0),
                "last_reported":  data.get("lastReportedAt", None),
                "is_whitelisted": data.get("isWhitelisted", False),
                "enrichment_source": "abuseipdb",
            }
            # Cache the result
            _ip_cache[ip] = result
            return result

    except urllib.error.HTTPError as e:
        if e.code == 429:
            # Rate limit hit — stop all API calls for this Lambda container lifetime
            _rate_limited = True
            logger.warning(f"AbuseIPDB rate limit (429) hit on {ip}. "
                           f"Disabling enrichment for remaining events this invocation.")
        else:
            logger.warning(f"AbuseIPDB HTTP {e.code} for {ip}")
    except urllib.error.URLError as e:
        logger.warning(f"AbuseIPDB network error for {ip}: {e.reason}")
    except Exception as e:
        logger.warning(f"AbuseIPDB unexpected error for {ip}: {e}")

    return _default_enrichment()


def _default_enrichment(rate_limited: bool = False) -> dict:
    """Safe defaults when enrichment fails — log is still stored."""
    return {
        "abuse_score":       -1,
        "country_code":      "UNKNOWN",
        "isp":               "UNKNOWN",
        "domain":            "UNKNOWN",
        "is_tor":            False,
        "total_reports":     0,
        "last_reported":     None,
        "is_whitelisted":    False,
        "enrichment_source": "rate_limited" if rate_limited else "failed",
    }


def _is_private_ip(ip: str) -> bool:
    """Skip enrichment for private/loopback IPs — they're not attackers."""
    private_prefixes = ("10.", "172.16.", "172.17.", "172.18.", "172.19.",
                        "172.20.", "172.21.", "172.22.", "172.23.", "172.24.",
                        "172.25.", "172.26.", "172.27.", "172.28.", "172.29.",
                        "172.30.", "172.31.", "192.168.", "127.", "::1", "fc", "fd")
    return ip.startswith(private_prefixes)


def enrich_event(event: dict, api_key: str) -> dict:
    """Merge AbuseIPDB enrichment fields into a Cowrie log event."""
    src_ip = event.get("src_ip", "")
    enrichment = {}

    if src_ip and not _is_private_ip(src_ip):
        enrichment = query_abuseipdb(src_ip, api_key)
    else:
        logger.info(f"Skipping private/missing IP: {src_ip!r}")

    return {
        **event,
        **enrichment,
        "enriched_at": datetime.now(timezone.utc).isoformat(),
        "pipeline":    "honeynet-lambda-v1",
    }


def lambda_handler(event, context):
    """
    Main Lambda entry point.
    Processes each S3 PutObject event, enriches Cowrie log lines,
    and writes results to the enriched bucket.
    """
    api_key = get_api_key()
    processed = 0
    errors = 0

    for record in event.get("Records", []):
        source_bucket = record["s3"]["bucket"]["name"]
        source_key    = record["s3"]["object"]["key"]

        logger.info(f"Processing: s3://{source_bucket}/{source_key}")

        try:
            obj = s3.get_object(Bucket=source_bucket, Key=source_key)
            raw_bytes = obj["Body"].read()
            content_encoding = obj.get("ContentEncoding", "")

            # Fluent Bit can gzip-compress S3 objects before upload.
            # Detect both explicit content-encoding and gzip magic bytes.
            if content_encoding == "gzip" or raw_bytes[:2] == b"\x1f\x8b":
                raw_content = gzip.decompress(raw_bytes).decode("utf-8")
            else:
                raw_content = raw_bytes.decode("utf-8")
        except Exception as e:
            logger.error(f"Failed to read s3://{source_bucket}/{source_key}: {e}")
            errors += 1
            continue

        enriched_lines = []
        for line in raw_content.strip().splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                log_event = json.loads(line)
                enriched  = enrich_event(log_event, api_key)
                enriched_lines.append(json.dumps(enriched))
                processed += 1
            except json.JSONDecodeError:
                logger.warning(f"Skipping non-JSON line: {line[:80]}")
            except Exception as e:
                logger.error(f"Failed to enrich event: {e}")
                errors += 1

        if enriched_lines:
            output_key    = f"enriched/{source_key}"
            enriched_body = "\n".join(enriched_lines)
            s3.put_object(
                Bucket=ENRICHED_BUCKET,
                Key=output_key,
                Body=enriched_body.encode("utf-8"),
                ContentType="application/x-ndjson",
                ServerSideEncryption="AES256",
            )
            logger.info(
                f"Written {len(enriched_lines)} records to "
                f"s3://{ENRICHED_BUCKET}/{output_key}"
            )

    logger.info(f"Done. Processed: {processed}, Errors: {errors}")
    return {"processed": processed, "errors": errors}
