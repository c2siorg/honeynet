#!/bin/bash
set -e

cd "$(dirname "$0")/../terraform"

echo "initializing..."
terraform init -backend-config=backend.tfvars

echo "planning..."
terraform plan -var-file=terraform.tfvars -out=honeynet.plan

echo "applying..."
terraform apply honeynet.plan

echo ""
echo "done. node IPs:"
terraform output honeypot_ips

echo ""
echo "grafana:"
terraform output grafana_url
