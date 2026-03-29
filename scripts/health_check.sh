#!/bin/bash
set -e

cd "$(dirname "$0")/../terraform"

IPS=$(terraform output -json honeypot_ips | jq -r '.[]')

if [ -z "$IPS" ]; then
  echo "no honeypot nodes found. has the infrastructure been deployed?"
  exit 1
fi

for ip in $IPS; do
  echo -n "checking $ip... "
  result=$(ssh -o StrictHostKeyChecking=no \
               -o ConnectTimeout=5 \
               ubuntu@"$ip" \
               "docker ps --format '{{.Names}}'" 2>/dev/null)

  if echo "$result" | grep -qE "cowrie|dionaea"; then
    echo "ok ($(echo "$result" | grep -E 'cowrie|dionaea'))"
  else
    echo "FAIL — no honeypot container running"
  fi
done
