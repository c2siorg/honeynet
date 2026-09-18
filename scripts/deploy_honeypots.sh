#!/usr/bin/env bash

set -euo pipefail

echo "Starting Honeynet deployment..."

command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed"; exit 1; }

cd terraform

terraform init
terraform apply -auto-approve

echo "Infrastructure deployed."

HONEYPOTS=$(terraform output -json honeypots)
LOG_SINK_BUCKET=$(terraform output -raw telemetry_log_sink_bucket)
TELEMETRY_REGION=$(terraform output -raw telemetry_region)

echo "Configuring honeypots with Ansible..."

INVENTORY_FILE="../ansible/inventory.ini"
echo "[honeynet]" > "$INVENTORY_FILE"

echo "$HONEYPOTS" | jq -r '
  to_entries[] | "\(.value.ip) region=\(.value.region) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/honeynet_key"
' >> "$INVENTORY_FILE"

cd ..

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i ansible/inventory.ini ansible/playbooks/install_honeypot.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/install_log_forwarder.yml \
  --extra-vars "s3_bucket=$LOG_SINK_BUCKET aws_region=${TELEMETRY_REGION:-us-east-1} cloud_provider=aws"

echo "Deployment complete."
echo "Raw logs are being shipped to S3 bucket: $LOG_SINK_BUCKET"
