#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if command -v checkov >/dev/null 2>&1; then
  (cd "$ROOT" && checkov --config .checkov.yaml)
else
  echo "checkov not found; install with: pip install checkov" >&2
  echo "Skipping Checkov; running Terraform only." >&2
fi
cd "$ROOT/terraform"
terraform init -backend=false
terraform fmt -recursive -check
terraform validate
