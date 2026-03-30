#!/bin/bash
set -e

# Update system
yum update -y

# Install Java (required for Logstash)
yum install -y java-1.8.0-openjdk

# Install Logstash
yum install -y https://artifacts.elastic.co/downloads/logstash/logstash-8.11.1-x86_64.rpm

# Create Logstash directories
mkdir -p /etc/logstash/conf.d
mkdir -p /opt/logstash/pipeline

# Configure Logstash
cat > /etc/logstash/logstash.yml << EOF
path.data: /var/lib/logstash
path.config: /etc/logstash/conf.d
pipeline.workers: 2
pipeline.batch.size: 125
pipeline.batch.delay: 50

http.host: "0.0.0.0"
http.port: 9600

EOF

# Copy pipeline configuration
cp /opt/logstash/pipeline/cowrie.conf /etc/logstash/conf.d/

# Create log directory
mkdir -p /var/log/logstash

# Start Logstash
systemctl enable logstash
systemctl start logstash

echo "Logstash installed and configured!"
echo "Processing Cowrie logs from Filebeat on port 5044"
echo "Elasticsearch output configured for ${ELASTICSEARCH_HOSTS}"
