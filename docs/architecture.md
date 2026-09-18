# Honeynet Architecture

## Overview

Honeynet combines distributed Cowrie deployment with a centralized telemetry and analytics layer. The current implementation is AWS-focused and validated end to end across multiple regions.

The architecture is organized into three layers:

- provisioning with Terraform
- configuration with Ansible
- collection and analytics with S3, Lambda, Glue, and Athena

## High-Level Flow

```text
Controller
   |
   | Terraform + Ansible
   v
Multi-region EC2 honeypots
   |
   | Cowrie JSON logs
   v
Fluent Bit
   |
   | S3 upload
   v
Raw S3 bucket
   |
   | S3 event notification
   v
Lambda enrichment
   |
   | enriched NDJSON
   v
Enriched S3 bucket
   |
   | Glue crawler
   v
Athena
```

## Infrastructure Layer

### Root Terraform Stack

The root stack in [main.tf](/e:/desktop-28.2.26/DSA/honeynet/terraform/main.tf) provisions and connects two modules:

- `module "honeypots"`
- `module "telemetry"`

This allows deployment and analytics infrastructure to be created together in one workflow.

### Honeypot Module

The honeypot module in [main.tf](/e:/desktop-28.2.26/DSA/honeynet/terraform/modules/honeypot/main.tf) provisions:

- EC2 instances in `us-east-1`, `eu-west-1`, and `ap-south-1`
- region-specific security groups
- SSH key pairs
- a shared IAM role and instance profile that allows raw log upload to the S3 sink bucket

Each honeypot node exposes:

- port `22` for administrative SSH access
- port `2222` for Cowrie attacker traffic

### Telemetry Module

The telemetry module in [main.tf](/e:/desktop-28.2.26/DSA/honeynet/terraform/modules/telemetry/main.tf) provisions:

- raw S3 log sink bucket
- enriched S3 bucket
- Athena results bucket
- AbuseIPDB secret in Secrets Manager
- Lambda enrichment function
- S3 event notification for raw uploads
- Glue database and crawler
- Athena workgroup

## Configuration Layer

### Honeypot Configuration

Ansible configures the EC2 nodes after Terraform finishes.

[install_honeypot.yml](/e:/desktop-28.2.26/DSA/honeynet/ansible/playbooks/install_honeypot.yml):

- installs Cowrie dependencies
- clones Cowrie
- creates the virtual environment
- installs Cowrie
- deploys a managed `cowrie.cfg`
- registers and starts the `cowrie` systemd service

The Cowrie template in [cowrie.cfg.j2](/e:/desktop-28.2.26/DSA/honeynet/ansible/templates/cowrie.cfg.j2) explicitly enables:

- SSH listener on port `2222`
- JSON output at `var/log/cowrie/cowrie.json`
- text logging for audit output

### Log Forwarder Configuration

[install_log_forwarder.yml](/e:/desktop-28.2.26/DSA/honeynet/ansible/playbooks/install_log_forwarder.yml):

- installs Fluent Bit
- configures the official package repository
- renders the S3 output configuration
- starts the `fluent-bit` systemd service

The template in [fluent-bit.conf.j2](/e:/desktop-28.2.26/DSA/honeynet/ansible/templates/fluent-bit.conf.j2) tails Cowrie JSON logs and writes them to the raw S3 bucket using the EC2 instance role.

## Telemetry Layer

### Raw Log Ingestion

Cowrie writes attacker events such as:

- `cowrie.session.connect`
- `cowrie.login.success`
- `cowrie.login.failed`
- `cowrie.command.input`

Fluent Bit uploads these records to the raw S3 bucket under:

```text
raw/<sensor_id>/YYYY/MM/DD/<object>
```

### Enrichment

The Lambda in [handler.py](/e:/desktop-28.2.26/DSA/honeynet/lambda/enrichment/handler.py):

- reads raw S3 objects
- handles gzip-compressed Fluent Bit uploads
- parses NDJSON Cowrie events
- queries AbuseIPDB for public attacker IPs
- appends enrichment fields such as:
  - `abuse_score`
  - `country_code`
  - `isp`
  - `domain`
  - `is_tor`
- writes enriched NDJSON to the enriched bucket

The function is triggered by S3 object creation events on the `raw/` prefix.

### Catalog and Query Layer

Glue crawls the enriched S3 prefix on a schedule and updates the schema in the `honeynet_attacks` database.

Athena then queries the enriched data using the `honeynet-attack-analysis` workgroup, with results written to the Athena results bucket.

## Operational Workflow

Typical workflow:

1. Run [deploy_honeypots.sh](/e:/desktop-28.2.26/DSA/honeynet/scripts/deploy_honeypots.sh).
2. Terraform provisions honeypots and telemetry resources.
3. The script generates `ansible/inventory.ini`.
4. Ansible installs Cowrie and Fluent Bit.
5. Attack traffic hits port `2222`.
6. Raw events land in S3.
7. Lambda enriches events.
8. Glue catalogs the enriched schema.
9. Athena queries the resulting dataset.

## Validation Status

This architecture has been validated with:

- live Cowrie SSH sessions on deployed EC2 honeypots
- raw log delivery into S3
- Lambda enrichment of uploaded events
- enriched record storage in S3
- Athena query execution over the enriched dataset

## Future Improvements

Natural next steps include:

- support for additional honeypot types such as Dionaea
- more robust normalized event schemas across honeypot families
- saved Athena query packs and analyst playbooks
- dashboarding on top of Athena query outputs
- broader multi-cloud node deployment support
