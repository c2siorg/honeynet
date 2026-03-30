# ELK Stack Verification Guide

## 🎯 Issue #18: Setup ELK Stack for Honeypot Log Collection

### Changes Made

1. **Elasticsearch Module**
   - Single-node cluster configuration
   - Security groups for HTTP (9200) and transport (9300)
   - Memory-optimized settings
   - Auto-discovery configuration

2. **Logstash Module**
   - JSON log parsing for Cowrie format
   - GeoIP enrichment for attacker location
   - Elasticsearch output configuration
   - Pipeline for honeypot log processing

3. **Kibana Module**
   - Web interface configuration
   - Elasticsearch integration
   - Security settings for development
   - Public access for dashboard

4. **Filebeat Integration**
   - Honeypot agent configuration
   - JSON log shipping from Cowrie
   - Template configuration for honeypot logs

### Deployment Steps

1. **Deploy ELK Infrastructure**
   ```bash
   cd infrastructure/terraform
   terraform init
   terraform apply -var="create_elk_stack=true"
   ```

2. **Verify Elasticsearch**
   ```bash
   # Get Elasticsearch endpoint
   terraform output elasticsearch_endpoint
   
   # Test connection
   curl http://<ELASTIC_IP>:9200/_cluster/health
   ```

3. **Verify Logstash Pipeline**
   ```bash
   # Check Logstash status
   ssh -i ~/.ssh/key.pem ec2-user@<LOGSTASH_IP>
   sudo systemctl status logstash
   
   # Test pipeline
   echo '{"timestamp":"2024-01-01T12:00:00Z","srcip":"1.2.3.4"}' | 
   curl -XPOST http://<LOGSTASH_IP>:5044 -H 'Content-Type: application/json'
   ```

4. **Verify Filebeat**
   ```bash
   # Check Filebeat on honeypot
   ssh -i ~/.ssh/key.pem ec2-user@<HONEYPOT_IP>
   sudo systemctl status filebeat
   
   # Test log shipping
   sudo tail -f /var/log/filebeat/filebeat
   ```

5. **Access Kibana Dashboard**
   ```bash
   # Get Kibana URL
   terraform output kibana_endpoint
   
   # Open in browser
   http://<KIBANA_IP>:5601
   ```

### Expected Results

- Elasticsearch cluster responds to health checks
- Logstash processes Cowrie JSON logs correctly
- Filebeat ships honeypot logs to Logstash
- Kibana dashboard displays honeypot data
- GeoIP enrichment shows attacker locations

### Success Criteria

- ✅ Elasticsearch cluster runs on port 9200
- ✅ Logstash processes logs and forwards to Elasticsearch
- ✅ Filebeat ships honeypot logs within 30 seconds
- ✅ Kibana dashboard displays attack data
- ✅ GeoIP enrichment shows geographic attack patterns

### Dashboard Setup

1. **Create Index Pattern**
   - Pattern: `honeypot-logs-*`
   - Time field: `@timestamp`

2. **Visualizations**
   - World Map: Attack source locations
   - Timeline: Attack frequency over time
   - Top IPs: Most active attackers
   - Usernames: Most attempted credentials

### Troubleshooting

**Common Issues**:
- Elasticsearch won't start: Check Java installation
- No logs in Kibana: Verify Filebeat → Logstash → Elasticsearch flow
- GeoIP not working: Install GeoIP database on Logstash

This enables real-time attack visibility and threat intelligence extraction from honeypot logs.
