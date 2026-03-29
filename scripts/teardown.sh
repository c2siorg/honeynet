#!/bin/bash
set -e

cd "$(dirname "$0")/../terraform"

echo "this will destroy all honeynet infrastructure."
read -p "are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "aborted."
  exit 0
fi

terraform destroy -var-file=terraform.tfvars -auto-approve
echo "all nodes destroyed."
