#!/bin/bash
set -e

apt-get update -y
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

if [ "${honeypot_type}" = "cowrie" ]; then
  docker run -d \
    --name cowrie \
    --restart always \
    -p 22:2222 \
    -v /honeynet/logs:/cowrie/var/log/cowrie \
    cowrie/cowrie:latest

elif [ "${honeypot_type}" = "dionaea" ]; then
  docker run -d \
    --name dionaea \
    --restart always \
    --net=host \
    -v /honeynet/logs:/opt/dionaea/var/log \
    dinotools/dionaea:latest
fi
