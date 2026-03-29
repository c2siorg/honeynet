#!/bin/bash
set -euxo pipefail
dnf install -y docker
systemctl enable --now docker
docker pull ${honeypot_image}
docker rm -f cowrie 2>/dev/null || true
docker run -d --name cowrie --restart unless-stopped -p 2222:2222 ${honeypot_image}
