#!/bin/bash
set -e

# Update system
yum update -y

# Install Kibana
yum install -y https://artifacts.elastic.co/downloads/kibana/kibana-8.11.1-x86_64.rpm

# Configure Kibana
cat > /etc/kibana/kibana.yml << EOF
server.host: "0.0.0.0"
server.port: 5601
elasticsearch.hosts: ["${ELASTICSEARCH_HOSTS}"]

# Security settings
xpack.security.enabled: false
xpack.monitoring.ui.container.elasticsearch.enabled: false

EOF

# Start Kibana
systemctl enable kibana
systemctl start kibana

echo "Kibana installed and configured!"
echo "Dashboard available at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5601"
echo "Connected to Elasticsearch at ${ELASTICSEARCH_HOSTS}"
