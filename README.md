# honeynet

Scalable, cloud-native honeypot deployment using Terraform. The goal is to provision isolated sensors in multiple regions—similar in spirit to [GeoDnsScanner](https://github.com/c2siorg/GeoDnsScanner)’s distributed layout, but for honeypots—so teams can collect behavioral telemetry and compare regional attack patterns.

## What’s in this repo

- **Terraform (AWS):** Dedicated VPC, EC2 sensor, security group exposing a Cowrie SSH honeypot on **port 2222**, optional VPC flow logs to CloudWatch, SSM-capable instance role for administration without a bastion.
- **Per-region vars:** `terraform/env/*.tfvars` for North America, Europe, and Asia-Pacific example regions.
- **Scripts:** `scripts/validate.sh` (fmt + validate), `scripts/deploy-region.sh` (apply with a chosen env file).

## Prerequisites

- Terraform `>= 1.5`, AWS CLI configured with credentials that can create VPC, EC2, IAM, and CloudWatch resources.
- Understand that a honeypot **will** receive untrusted traffic; use a dedicated AWS account or strict account guardrails.

## Quick start (single region)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (region, labels, tighten admin_ssh_cidr, optional key_name)

terraform init
terraform plan
terraform apply
```

Outputs include the public IP and the CloudWatch log group for flow logs (if enabled). Connect scanners to the honeypot on **TCP 2222** (Cowrie).

## Multi-region deployment

Deploy **once per region** with separate state (recommended: remote state per region—see [docs/ISSUES.md](docs/ISSUES.md) issue **#4**):

```bash
./scripts/deploy-region.sh terraform/env/us-east-1.tfvars
./scripts/deploy-region.sh terraform/env/eu-west-1.tfvars
./scripts/deploy-region.sh terraform/env/ap-southeast-1.tfvars
```

Use different backend keys or directories so each region keeps its own `terraform.tfstate`.

## Contributing

1. Open or pick an item from [docs/ISSUES.md](docs/ISSUES.md).
2. Branch from `main`, implement with focused commits.
3. Run `./scripts/validate.sh` before pushing (requires Terraform installed locally).
4. Open a PR describing behavior change and any new variables.

## Security notes

- Restrict `admin_ssh_cidr` and prefer SSM Session Manager (`AmazonSSMManagedInstanceCore` is attached) instead of wide SSH.
- Review AWS costs (NAT not used; instances are in a public subnet with public IP for inbound honeypot traffic).
- This is **not** legal or compliance advice; ensure deployment aligns with your policies and local law.

## License

See [LICENSE](LICENSE).
