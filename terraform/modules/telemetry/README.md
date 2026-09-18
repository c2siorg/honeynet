# Telemetry Module — Threat Intelligence Data Pipeline

This module provisions a fully automated, serverless threat intelligence pipeline
that transforms raw honeypot logs into enriched, queryable attack data.

## Architecture

```
Honeypot Node (any cloud)
        ↓  Filebeat over TLS
S3 Log Sink (encrypted, append-only)
        ↓  S3 event trigger
Lambda (Python) — parses Cowrie JSON, enriches IP via AbuseIPDB
        ↓  writes enriched JSON
S3 Enriched Logs
        ↓  hourly crawl
Glue Catalog (auto schema discovery)
        ↓  SQL
Athena Workgroup — query attack data directly
```

## Resources Provisioned

| Resource                         | Purpose                                                |
| -------------------------------- | ------------------------------------------------------ |
| `aws_s3_bucket.log_sink`         | Receives raw Cowrie/Dionaea logs                       |
| `aws_s3_bucket.enriched_logs`    | Stores Lambda-enriched attack records                  |
| `aws_lambda_function.enrichment` | Python function: parses IP → AbuseIPDB → enriched JSON |
| `aws_secretsmanager_secret`      | Stores AbuseIPDB API key securely                      |
| `aws_glue_crawler`               | Auto-discovers schema from enriched logs hourly        |
| `aws_athena_workgroup`           | SQL query interface for attack analysis                |

## Usage

```hcl
module "telemetry" {
  source            = "./modules/telemetry"
  name_prefix       = "honeynet"
  aws_region        = "us-east-1"
  abuseipdb_api_key = var.abuseipdb_api_key
}
```

## Example Athena Queries

```sql
-- Top attacking IPs
SELECT src_ip, COUNT(*) as attempts
FROM honeynet_attacks.enriched
ORDER BY attempts DESC LIMIT 20;

-- High-risk IPs (abuse score > 80)
SELECT src_ip, abuse_score, country_code, isp
FROM honeynet_attacks.enriched
WHERE abuse_score > 80
ORDER BY abuse_score DESC;

-- Attack volume by country
SELECT country_code, COUNT(*) as attacks
FROM honeynet_attacks.enriched
GROUP BY country_code
ORDER BY attacks DESC;

-- Most common credential attempts
SELECT username, password, COUNT(*) as tries
FROM honeynet_attacks.enriched
WHERE eventid = 'cowrie.login.failed'
GROUP BY username, password
ORDER BY tries DESC LIMIT 20;
```

## Prerequisites

- Free AbuseIPDB API key: https://www.abuseipdb.com/register
- Store as Terraform variable (never hardcode):

```bash
  export TF_VAR_abuseipdb_api_key="your_key_here"
```
