#!/usr/bin/env bash
# Deploy one regional stack using env/*.tfvars (separate state file per region recommended).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:?Usage: $0 terraform/env/<region>.tfvars [terraform plan|apply args]}"

cd "$ROOT/terraform"
terraform init
terraform apply -var-file="$ROOT/$ENV_FILE" "${@:2}"
