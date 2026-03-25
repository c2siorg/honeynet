#!/bin/bash

# Configuration
IMAGE_NAME="honeynet-node"
MONITOR_COMPOSE="monitoring/docker-compose.yml"

# Build the Honeypot Image
TAG=$(date +%Y%m%d-%H%M%S)
echo "Building Honeypot image with tag: $TAG..."

if docker build -t $IMAGE_NAME:$TAG . ; then
    docker tag $IMAGE_NAME:$TAG $IMAGE_NAME:latest
    echo "Build Successful: $IMAGE_NAME:latest"
else
    echo "Build Failed. Check your Dockerfile."
    exit 1
fi

# Option to start the Monitoring Stack
read -p "📊 Would you like to start the Monitoring Stack (Prometheus/Grafana)? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    if [ -f "$MONITOR_COMPOSE" ]; then
        echo "Starting Prometheus and Grafana..."
        docker-compose -f $MONITOR_COMPOSE up -d
        echo "Grafana: http://localhost:3000 (admin/admin)"
        echo "Prometheus: http://localhost:9090"
    else
        echo " Monitoring compose file not found at $MONITOR_COMPOSE"
    fi
fi