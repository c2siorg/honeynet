# Honeynet

Honeynet is a scalable, cloud-native honeypot deployment framework that uses Terraform and Ansible to provision distributed honeypot infrastructure, collect attacker activity, and transform raw logs into centralized threat intelligence.

The current validated implementation uses Cowrie as the active honeypot and AWS as the active cloud target, but the project is structured as a broader framework that can grow to support additional honeypots, richer schemas, and wider multi-cloud deployment over time.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

## Project Goal

This project is designed to help security teams and researchers:

- deploy honeypots across multiple geographic regions
- capture attacker behavior from realistic cloud targets
- centralize raw logs instead of losing them on instance termination
- enrich attacker activity with external threat intelligence
- query the resulting dataset for investigation and analysis

## Current Status

The currently implemented and validated path is:

```text
Cowrie -> Fluent Bit -> raw S3 -> Lambda enrichment -> enriched S3 -> Glue -> Athena
```

What is implemented today:

- multi-region EC2 honeypot deployment with Terraform
- Ansible automation for Cowrie installation
- Fluent Bit log forwarding from honeypot nodes into S3
- Lambda-based AbuseIPDB enrichment
- Glue crawler schema discovery
- Athena queries over enriched attack logs

What the framework is intended to support over time:

- additional honeypots such as Dionaea, Conpot, or web honeypots
- additional cloud providers
- normalized schemas across honeypot types
- dashboards and analyst playbooks
- stronger automation and validation around telemetry

## High-Level Architecture

```text
Controller / Operator Machine
        |
        | Terraform + Ansible
        v
Multi-region Honeypot Nodes
        |
        | Cowrie JSON logs
        v
Fluent Bit
        |
        | S3 upload
        v
Raw S3 Log Sink
        |
        | S3 ObjectCreated trigger
        v
Lambda Enrichment (AbuseIPDB)
        |
        v
Enriched S3 Logs
        |
        | Glue crawler
        v
Athena SQL Queries
```

For more detail, see [architecture.md](/e:/desktop-28.2.26/DSA/honeynet/docs/architecture.md).

## Repository Structure

```text
honeynet/
├── ansible/
│   ├── inventory.ini
│   ├── playbooks/
│   │   ├── install_honeypot.yml
│   │   └── install_log_forwarder.yml
│   └── templates/
│       ├── cowrie.cfg.j2
│       └── fluent-bit.conf.j2
├── docs/
│   └── architecture.md
├── lambda/
│   └── enrichment/
│       └── handler.py
├── scripts/
│   └── deploy_honeypots.sh
├── terraform/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── modules/
│       ├── honeypot/
│       └── telemetry/
└── CONTRIBUTING.md
```

## Environment Setup

This section walks through the full local environment setup from AWS login through deployment and testing.

### 1. Install Required Tools

Install the following on your local machine:

- Git
- Terraform 1.5+
- Ansible
- `jq`
- AWS CLI v2
- SSH client

Recommended verification:

```bash
git --version
terraform version
ansible --version
jq --version
aws --version
ssh -V
```

### 2. Create or Prepare an AWS Account

You need an AWS account with permission to manage:

- EC2
- IAM
- S3
- Lambda
- Secrets Manager
- Glue
- Athena
- CloudWatch Logs

If you are using IAM Identity Center, federated login, or an IAM user, make sure the credentials you use locally can create and modify these resources.

### 3. Configure AWS CLI Authentication

Configure AWS CLI locally:

```bash
aws configure
```

Provide:

- AWS Access Key ID
- AWS Secret Access Key
- default region, for example `us-east-1`
- output format, for example `json`

Verify the active identity:

```bash
aws sts get-caller-identity
```

If that command fails, fix AWS authentication before trying to deploy the project.

### 4. Create an SSH Key for Honeypot Access

Create a dedicated SSH keypair if you do not already have one:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/honeynet_key
```

This gives you:

- private key: `~/.ssh/honeynet_key`
- public key: `~/.ssh/honeynet_key.pub`

The current Terraform defaults expect the public key path defined in [variables.tf](/e:/desktop-28.2.26/DSA/honeynet/terraform/variables.tf). Update that variable if your key lives elsewhere.

### 5. Create an AbuseIPDB API Key

The enrichment Lambda uses AbuseIPDB to append threat intelligence fields to attacker IPs.

Create an account at:

- `https://www.abuseipdb.com/`

Generate an API key and store it locally in an ignored tfvars file.

Create:

```text
terraform/secrets.auto.tfvars
```

with:

```hcl
abuseipdb_api_key = "your_abuseipdb_api_key"
```

This file is ignored by git and should never be committed.

### 6. Clone the Repository

```bash
git clone https://github.com/c2siorg/honeynet.git
cd honeynet
```

### 7. Review Terraform Variables

Open [variables.tf](/e:/desktop-28.2.26/DSA/honeynet/terraform/variables.tf) and check these values:

- `name_prefix`
- `environment`
- `ssh_public_key_path`
- `honeypot_instance_type`
- `telemetry_region`

Defaults are provided, but you may want to customize:

- naming
- instance size
- SSH public key path
- environment label

### 8. Initialize Terraform

```bash
cd terraform
terraform init
terraform validate
cd ..
```

### 9. Deploy the Full Stack

Use the deployment script:

```bash
./scripts/deploy_honeypots.sh
```

This script:

- runs `terraform init`
- runs `terraform apply`
- reads Terraform outputs
- writes `ansible/inventory.ini`
- installs Cowrie on the deployed nodes
- installs and configures Fluent Bit on those nodes

### 10. Confirm Infrastructure Outputs

After deployment, Terraform should output:

- honeypot IPs
- raw log sink bucket
- enriched logs bucket
- Glue database
- Athena workgroup
- telemetry region

You can re-check outputs manually:

```bash
cd terraform
terraform output
cd ..
```

## Running and Testing the Project

### 1. Confirm Honeypot Nodes Exist

Open AWS EC2 and confirm three instances are present in:

- `us-east-1`
- `eu-west-1`
- `ap-south-1`

### 2. Confirm Administrative SSH Access

Use the generated inventory or the public IPs to connect as `ubuntu`:

```bash
ssh -i ~/.ssh/honeynet_key ubuntu@<public-ip>
```

### 3. Confirm Cowrie Is Running

On a honeypot node:

```bash
sudo systemctl status cowrie --no-pager
sudo journalctl -u cowrie -n 50 --no-pager
```

### 4. Generate Honeypot Traffic

Trigger a Cowrie session on port `2222`:

```bash
ssh root@<public-ip> -p 2222
```

Try a password and run a few commands if Cowrie presents a fake shell, for example:

```bash
whoami
ls
uname -a
sudo apt install nginx
```

Depending on the session, Cowrie may provide a fake shell or may terminate after authentication. Both behaviors can still generate attack telemetry.

### 5. Confirm Cowrie JSON Logging

On the honeypot node:

```bash
ls -la /home/ubuntu/cowrie/var/log/cowrie
tail -n 20 /home/ubuntu/cowrie/var/log/cowrie/cowrie.json
```

You should see events such as:

- `cowrie.session.connect`
- `cowrie.login.success`
- `cowrie.login.failed`
- `cowrie.command.input`

### 6. Confirm Fluent Bit Is Running

On the honeypot node:

```bash
sudo systemctl status fluent-bit --no-pager
sudo journalctl -u fluent-bit -n 100 --no-pager
```

### 7. Confirm Raw S3 Uploads

In AWS S3, check the raw log sink bucket. You should see objects under:

```text
raw/<sensor_id>/YYYY/MM/DD/
```

### 8. Confirm Lambda Enrichment

Check the Lambda function:

- `honeynet-ip-enrichment`

Review CloudWatch logs:

```bash
aws logs tail /aws/lambda/honeynet-ip-enrichment --since 30m --region us-east-1
```

You should see it processing raw objects and writing enriched output.

### 9. Confirm Enriched S3 Output

In the enriched bucket, check for objects under:

```text
enriched/raw/<sensor_id>/YYYY/MM/DD/
```

Sample enriched fields include:

- `abuse_score`
- `country_code`
- `isp`
- `domain`
- `is_tor`
- `enrichment_source`
- `enriched_at`

### 10. Run the Glue Crawler

Start the crawler manually the first time:

```bash
aws glue start-crawler --name honeynet-attack-log-crawler --region us-east-1
```

Check status:

```bash
aws glue get-crawler --name honeynet-attack-log-crawler --region us-east-1
```

Wait until the crawler state returns to `READY`.

### 11. Query Data in Athena

Use Athena workgroup:

- `honeynet-attack-analysis`

Use database:

- `honeynet_attacks`

Then run queries against table:

- `enriched`

Example:

```sql
SELECT src_ip, eventid, input, abuse_score, country_code, isp
FROM enriched
ORDER BY enriched_at DESC
LIMIT 20;
```

More example queries:

```sql
SELECT src_ip, COUNT(*) AS attempts
FROM enriched
GROUP BY src_ip
ORDER BY attempts DESC
LIMIT 10;
```

```sql
SELECT country_code, COUNT(*) AS attacks
FROM enriched
GROUP BY country_code
ORDER BY attacks DESC
LIMIT 10;
```

```sql
SELECT username, password, COUNT(*) AS tries
FROM enriched
WHERE eventid = 'cowrie.login.failed'
GROUP BY username, password
ORDER BY tries DESC
LIMIT 20;
```

## Current Implementation Notes

The current codebase is validated around Cowrie because it provides a clear SSH interaction path and structured event output. That is the current implemented honeypot, not the architectural limit of the project.

The repo is intentionally moving toward:

- more honeypot types
- richer telemetry normalization
- stronger multi-cloud support
- better analyst workflows on top of enriched data

## Development Notes

- `ansible/inventory.ini` is generated during deployment
- `terraform/modules/telemetry/lambda_enrichment.zip` is generated by Terraform and should not be committed
- when `lambda/enrichment/handler.py` changes, run `terraform apply` again so AWS Lambda is updated
- when Terraform modules change, rerun `terraform init` if Terraform asks to reinitialize

## Troubleshooting

### Raw bucket gets objects but enriched bucket stays empty

Check:

- Lambda CloudWatch logs
- S3 bucket notification configuration
- whether Fluent Bit uploads are gzip-compressed and Lambda can read them

### Fluent Bit cannot upload to S3

Check:

- EC2 instance profile attachment
- `aws_credentials` messages in `journalctl -u fluent-bit`
- IAM permissions to the raw log sink bucket

### Cowrie works on port `2222` but no logs appear

Check:

- `sudo systemctl status cowrie`
- `/home/ubuntu/cowrie/var/log/cowrie/cowrie.json`
- the deployed Cowrie config template

### Athena cannot run queries

Check:

- Glue crawler has completed successfully
- the `honeynet-attack-analysis` workgroup is selected
- Athena output location is configured

## Contributing

See [CONTRIBUTING.md](/e:/desktop-28.2.26/DSA/honeynet/CONTRIBUTING.md).

## License

This project is licensed under the Apache 2.0 License. See [LICENSE](/e:/desktop-28.2.26/DSA/honeynet/LICENSE) for details.
