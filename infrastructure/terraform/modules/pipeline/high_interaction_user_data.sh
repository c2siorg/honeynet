#!/bin/bash
set -e

# Update system
yum update -y

# Install required packages
yum install -y python3 python3-pip docker git

# Install Python dependencies
pip3 install kafka-python requests cowrie

# Create high-interaction honeypot directory
mkdir -p /opt/high_interaction
cd /opt/high_interaction

# Create high-interaction honeypot with Cowrie
cat > high_interaction_honeypot.py << 'EOF'
#!/usr/bin/env python3
import json
import time
import logging
import subprocess
from datetime import datetime
from kafka import KafkaProducer

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HighInteractionHoneypot:
    def __init__(self, honeypot_id, pipeline_endpoint, kafka_endpoint):
        self.honeypot_id = honeypot_id
        self.pipeline_endpoint = pipeline_endpoint
        self.kafka_producer = KafkaProducer(
            bootstrap_servers=[kafka_endpoint],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        self.cowrie_process = None
        
    def start_honeypot(self):
        """Start Cowrie honeypot for deep analysis"""
        logger.info(f"Starting high-interaction honeypot {self.honeypot_id}")
        
        # Start Cowrie in background
        try:
            self.cowrie_process = subprocess.Popen([
                'python3', '-m', 'cowrie',
                '--config', 'cowrie.cfg'
            ], cwd='/opt/cowrie')
            
            # Send startup event
            startup_event = {
                'event_type': 'HONEYPOT_STARTED',
                'honeypot_id': self.honeypot_id,
                'honeypot_type': 'HIGH_INTERACTION',
                'timestamp': datetime.utcnow().isoformat()
            }
            self.kafka_producer.send('honeypot_events', startup_event)
            
            logger.info("Cowrie honeypot started successfully")
            
        except Exception as e:
            logger.error(f"Failed to start Cowrie: {e}")
            return False
        
        return True
    
    def monitor_honeypot(self):
        """Monitor honeypot activity"""
        if not self.cowrie_process:
            return
            
        # Monitor Cowrie logs
        try:
            with open('/opt/cowrie/log/cowrie.json', 'r') as f:
                for line in f:
                    try:
                        log_entry = json.loads(line.strip())
                        
                        # Enrich with honeypot metadata
                        enriched_entry = {
                            'event_type': 'HONEYPOT_ACTIVITY',
                            'honeypot_id': self.honeypot_id,
                            'honeypot_type': 'HIGH_INTERACTION',
                            'raw_log': log_entry,
                            'timestamp': datetime.utcnow().isoformat(),
                            'analysis_level': 'deep'
                        }
                        
                        # Send to pipeline
                        self.kafka_producer.send('honeypot_events', enriched_entry)
                        
                        # Send critical events to pipeline API
                        if self.is_critical_attack(log_entry):
                            self.send_critical_event(log_entry)
                            
                    except json.JSONDecodeError:
                        continue
                        
        except FileNotFoundError:
            logger.warning("Cowrie log file not found")
    
    def is_critical_attack(self, log_entry):
        """Identify critical attacks for immediate response"""
        critical_indicators = [
            'root login successful',
            'malware upload',
            'command injection',
            'privilege escalation'
        ]
        
        log_message = log_entry.get('message', '').lower()
        return any(indicator in log_message for indicator in critical_indicators)
    
    def send_critical_event(self, log_entry):
        """Send critical attack to pipeline"""
        try:
            import requests
            event = {
                'event_type': 'CRITICAL_ATTACK',
                'honeypot_id': self.honeypot_id,
                'attack_data': log_entry,
                'urgency': 'high',
                'timestamp': datetime.utcnow().isoformat()
            }
            
            response = requests.post(
                f"http://{self.pipeline_endpoint}:8080/critical-attack",
                json=event,
                timeout=5
            )
            
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Failed to send critical event: {e}")
            return False
    
    def stop_honeypot(self):
        """Stop honeypot gracefully"""
        if self.cowrie_process:
            self.cowrie_process.terminate()
            self.cowrie_process.wait()
            
            # Send termination event
            terminate_event = {
                'event_type': 'HONEYPOT_STOPPED',
                'honeypot_id': self.honeypot_id,
                'reason': 'MANUAL_TERMINATION',
                'timestamp': datetime.utcnow().isoformat()
            }
            self.kafka_producer.send('honeypot_events', terminate_event)
            
            logger.info(f"High-interaction honeypot {self.honeypot_id} stopped")

# Start honeypot
if __name__ == "__main__":
    honeypot_id = socket.gethostname()
    pipeline_endpoint = "${PIPELINE_ENDPOINT}"
    kafka_endpoint = "${KAFKA_ENDPOINT}"
    
    honeypot = HighInteractionHoneypot(honeypot_id, pipeline_endpoint, kafka_endpoint)
    
    if honeypot.start_honeypot():
        # Monitor in background
        import threading
        
        monitor_thread = threading.Thread(target=honeypot.monitor_honeypot)
        monitor_thread.daemon = True
        monitor_thread.start()
        
        try:
            while True:
                time.sleep(60)  # Check every minute
        except KeyboardInterrupt:
            honeypot.stop_honeypot()
EOF

# Install Cowrie
git clone https://github.com/cowrie/cowrie.git /opt/cowrie
cd /opt/cowrie
pip3 install -r requirements.txt

# Configure Cowrie
cat > cowrie.cfg << EOF
[honeypot]
ssh_port = 2222
telnet_port = 2223

[output_json]
enabled = true
logfile = log/cowrie.json

[output_syslog]
enabled = false

[output_textlog]
enabled = false
EOF

# Create log directory
mkdir -p /opt/cowrie/log

# Create systemd service
cat > /etc/systemd/system/high-interaction-honeypot.service << EOF
[Unit]
Description=High-Interaction Honeypot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/high_interaction
ExecStart=/usr/bin/python3 /opt/high_interaction/high_interaction_honeypot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start honeypot
systemctl enable high-interaction-honeypot
# Note: Don't start automatically - will be started by pipeline

echo "High-interaction honeypot installed!"
echo "Honeypot ID: $(hostname)"
echo "Pipeline endpoint: ${PIPELINE_ENDPOINT}"
echo "Kafka endpoint: ${KAFKA_ENDPOINT}"
