#!/bin/bash
set -e

apt-get update -y
apt-get install -y docker.io docker-compose
systemctl enable docker
systemctl start docker

mkdir -p /honeynet/monitoring
cat > /honeynet/monitoring/docker-compose.yml << COMPOSE
version: "3"
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: always

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    restart: always
COMPOSE

# write prometheus scrape config from the honeypot IPs passed in
cat > /honeynet/monitoring/prometheus.yml << PROM
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: honeypots
    static_configs:
      - targets: [$(echo ${honeypot_ips} | tr ',' '\n' | sed "s/^/'/;s/$/:9100'/" | tr '\n' ',')]
PROM

cd /honeynet/monitoring && docker-compose up -d
