#!/bin/bash
set -e

# Update system
yum update -y

# Install Java (required for Elasticsearch)
yum install -y java-1.8.0-openjdk

# Install Elasticsearch
yum install -y https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.11.1-x86_64.rpm

# Configure Elasticsearch
cat > /etc/elasticsearch/elasticsearch.yml << EOF
cluster.name: honeynet-cluster
node.name: ${HOSTNAME}
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node

# Memory settings
bootstrap.memory_lock: true
xpack.security.enabled: false

EOF

# Create data directory
mkdir -p /var/lib/elasticsearch
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch

# Start Elasticsearch
systemctl enable elasticsearch
systemctl start elasticsearch

echo "Elasticsearch installed and configured!"
echo "Node running on http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9200"
echo "Cluster: honeynet-cluster"
