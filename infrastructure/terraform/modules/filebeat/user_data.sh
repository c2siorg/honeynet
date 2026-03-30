#!/bin/bash
set -e

# Update system
yum update -y

# Install Filebeat
yum install -y https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.1-x86_64.rpm

# Configure Filebeat for Cowrie logs
cat > /etc/filebeat/filebeat.yml << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /opt/honeypot/cowrie/log/cowrie.json

output.elasticsearch:
  hosts: ["${elasticsearch_endpoint}:9200"]
  index: "honeypot-logs-%{+yyyy.MM.dd}"

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - dissect:
      tokenizer: "%{TIMESTAMP_ISO8601} %{LOGLEVEL} %{EVENTID} %{SESSION} %{SENSOR} %{SRCIP} %{DSTIP} %{SRCPORT} %{DSTPORT} %{USERNAME} %{PASSWORD} %{COMMAND} %{VERSION} %{INPUT} %{OUTPUT}"
      field: "message"
      target_prefix: "cowrie."

setup.kibana:
  host: "${kibana_endpoint}"

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644

EOF

# Create log directory
mkdir -p /var/log/filebeat

# Start Filebeat
systemctl enable filebeat
systemctl start filebeat

echo "Filebeat installed and configured for Cowrie logs!"
echo "Shipping logs to Elasticsearch at ${elasticsearch_endpoint}"
echo "Kibana dashboard available at ${kibana_endpoint}"
