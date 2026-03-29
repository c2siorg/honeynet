# honeynet

Terraform-based framework for deploying honeypots across multiple cloud regions.

One config file, one command — honeypot nodes running in NA, EU, and APAC,
with a central Prometheus/Grafana stack collecting logs from all of them.

Built for GSoC 2026 under C2SI. Architecture follows the same pattern as
GeoDNSScanner but adapted for honeypot infrastructure on AWS.

## what it does

- provisions EC2 instances per region via Terraform
- each node runs Cowrie or Dionaea inside Docker
- central monitoring node collects metrics via Prometheus, visualized in Grafana
- scripts handle the full lifecycle: deploy, health check, teardown

## usage
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# fill in your regions, key path, etc.

./scripts/deploy.sh
./scripts/health_check.sh
./scripts/teardown.sh
```

## requirements

- Terraform >= 1.5.0
- AWS account + credentials configured via `aws configure`
- SSH key pair

## project structure
```
terraform/
  modules/
    honeypot-node/    ec2 instance + docker bootstrap per region
    monitoring/       prometheus + grafana central stack
    networking/       vpc and subnet config
  main.tf
  variables.tf
  outputs.tf
  terraform.tfvars.example
scripts/
  deploy.sh
  teardown.sh
  health_check.sh
docker/
  cowrie/
  dionaea/
.github/
  workflows/
    terraform-validate.yml
```

## status

Core structure in place. Multi-region wiring, monitoring stack,
and CI pipeline are the next milestones.
