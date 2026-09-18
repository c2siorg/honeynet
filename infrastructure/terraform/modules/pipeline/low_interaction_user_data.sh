#!/bin/bash
set -e

# Update system
yum update -y

# Install required packages
yum install -y python3 python3-pip docker

# Install Python dependencies
pip3 install kafka-python requests scapy

# Create honeypot directory
mkdir -p /opt/low_interaction
cd /opt/low_interaction

# Create low-interaction honeypot
cat > low_interaction_honeypot.py << 'EOF'
#!/usr/bin/env python3
import json
import time
import logging
import socket
import threading
from datetime import datetime
from kafka import KafkaProducer
from scapy.all import sniff, IP, TCP, UDP

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LowInteractionHoneypot:
    def __init__(self, honeypot_id, pipeline_endpoint, kafka_endpoint):
        self.honeypot_id = honeypot_id
        self.pipeline_endpoint = pipeline_endpoint
        self.kafka_producer = KafkaProducer(
            bootstrap_servers=[kafka_endpoint],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        self.attack_patterns = {}
        
    def detect_attack(self, packet):
        """Detect suspicious activity"""
        if IP in packet and TCP in packet:
            src_ip = packet[IP].src
            dst_port = packet[TCP].dport
            
            # Check for suspicious patterns
            attack_type = self.classify_attack(packet)
            
            if attack_type:
                event = {
                    'timestamp': datetime.utcnow().isoformat(),
                    'source_ip': src_ip,
                    'target_port': dst_port,
                    'attack_type': attack_type,
                    'honeypot_id': self.honeypot_id,
                    'severity': 'medium',
                    'metadata': {
                        'packet_size': len(packet),
                        'protocol': 'TCP',
                        'flags': str(packet[TCP].flags)
                    }
                }
                
                # Send to pipeline
                self.kafka_producer.send('honeypot_events', event)
                
                # Send to pipeline API for analysis
                self.send_to_pipeline(event)
                
                logger.info(f"Detected {attack_type} from {src_ip}")
    
    def classify_attack(self, packet):
        """Classify attack type"""
        if TCP in packet:
            dst_port = packet[TCP].dport
            
            # Check for common attack patterns
            if dst_port == 22:
                return 'ssh_brute_force'
            elif dst_port == 80:
                return 'web_attack'
            elif dst_port == 23:
                return 'telnet_attack'
            elif dst_port == 21:
                return 'ftp_attack'
        
        return None
    
    def send_to_pipeline(self, event):
        """Send event to pipeline for analysis"""
        try:
            import requests
            response = requests.post(
                f"http://{self.pipeline_endpoint}:8080/attack-event",
                json=event,
                timeout=5
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Failed to send to pipeline: {e}")
            return False
    
    def start_monitoring(self):
        """Start packet monitoring"""
        logger.info(f"Starting low-interaction honeypot {self.honeypot_id}")
        
        # Start packet capture
        sniff(
            filter="tcp",
            prn=self.detect_attack,
            store=False
        )

# Start honeypot
if __name__ == "__main__":
    honeypot_id = socket.gethostname()
    pipeline_endpoint = "${PIPELINE_ENDPOINT}"
    kafka_endpoint = "${KAFKA_ENDPOINT}"
    
    honeypot = LowInteractionHoneypot(honeypot_id, pipeline_endpoint, kafka_endpoint)
    honeypot.start_monitoring()
EOF

# Create systemd service
cat > /etc/systemd/system/low-interaction-honeypot.service << EOF
[Unit]
Description=Low-Interaction Honeypot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/low_interaction
ExecStart=/usr/bin/python3 /opt/low_interaction/low_interaction_honeypot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start honeypot
systemctl enable low-interaction-honeypot
systemctl start low-interaction-honeypot

echo "Low-interaction honeypot installed and running!"
echo "Honeypot ID: $(hostname)"
echo "Pipeline endpoint: ${PIPELINE_ENDPOINT}"
echo "Kafka endpoint: ${KAFKA_ENDPOINT}"
