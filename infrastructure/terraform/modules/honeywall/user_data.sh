#!/bin/bash
set -e

# Update system
yum update -y

# Install required packages
yum install -y iptables-services nftables python3 python3-pip git

# Install Python dependencies
pip3 install scapy netaddr requests geoip2

# Create honeywall directory
mkdir -p /opt/honeywall
cd /opt/honeywall

# Create honeywall application
cat > honeywall.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
import json
import time
import logging
import subprocess
import socket
import struct
from datetime import datetime
from scapy.all import *
from geoip2.database import Reader
from geoip2.errors import AddressNotFoundError

class Honeywall:
    def __init__(self):
        self.setup_logging()
        self.load_config()
        self.setup_routing()
        self.geoip_reader = self.setup_geoip()
        
    def setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/honeywall.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def load_config(self):
        self.config = {
            'honeypot_ip': '${HONEYPOT_PRIVATE_IP}',
            'suspicious_ports': [22, 23, 80, 443, 3389],
            'legitimate_ips': self.load_legitimate_ips(),
            'reputation_threshold': 0.7,
            'rate_limit': {
                'connections_per_minute': 10,
                'block_duration': 300
            }
        }
        
    def load_legitimate_ips(self):
        # Load legitimate IP ranges from config file
        legitimate_file = '/opt/honeywall/legitimate_ips.txt'
        if os.path.exists(legitimate_file):
            with open(legitimate_file, 'r') as f:
                return [line.strip() for line in f if line.strip()]
        return []
        
    def setup_geoip(self):
        try:
            return Reader('/opt/honeywall/GeoLite2-City.mmdb')
        except:
            self.logger.warning("GeoIP database not found")
            return None
            
    def setup_routing(self):
        # Enable IP forwarding
        subprocess.run(['sysctl', '-w', 'net.ipv4.ip_forward=1'])
        
        # Clear existing rules
        subprocess.run(['iptables', '-F'])
        subprocess.run(['iptables', '-t', 'nat', '-F'])
        
        # Setup NAT for honeypot traffic
        subprocess.run([
            'iptables', '-t', 'nat', '-A', 'PREROUTING',
            '-p', 'tcp', '--dport', '2222',
            '-j', 'DNAT', '--to-destination', self.config['honeypot_ip'] + ':2222'
        ])
        
        subprocess.run([
            'iptables', '-t', 'nat', '-A', 'PREROUTING',
            '-p', 'tcp', '--dport', '2223',
            '-j', 'DNAT', '--to-destination', self.config['honeypot_ip'] + ':2223'
        ])
        
    def analyze_traffic(self, packet):
        if IP in packet and TCP in packet:
            src_ip = packet[IP].src
            dst_port = packet[TCP].dport
            
            # Traffic classification logic
            if self.is_suspicious(src_ip, dst_port):
                return self.route_to_honeypot(packet)
            elif self.is_legitimate(src_ip):
                return self.route_to_real_system(packet)
            else:
                return self.route_to_decoy(packet)
                
    def is_suspicious(self, src_ip, dst_port):
        # Check if port is commonly targeted
        if dst_port in self.config['suspicious_ports']:
            return True
            
        # Check reputation (placeholder for real reputation service)
        if self.check_reputation(src_ip) > self.config['reputation_threshold']:
            return True
            
        # Check rate limiting
        if self.is_rate_limited(src_ip):
            return True
            
        return False
        
    def is_legitimate(self, src_ip):
        # Check against legitimate IP ranges
        for legit_range in self.config['legitimate_ips']:
            if self.ip_in_range(src_ip, legit_range):
                return True
        return False
        
    def check_reputation(self, src_ip):
        # Placeholder for reputation checking
        # In production, integrate with threat intelligence feeds
        suspicious_indicators = [
            src_ip.startswith('10.'),
            src_ip.startswith('192.168.'),
            src_ip.startswith('172.')
        ]
        return 0.8 if any(suspicious_indicators) else 0.1
        
    def is_rate_limited(self, src_ip):
        # Check connection rate
        key = f"rate_limit_{src_ip}"
        current_time = time.time()
        
        # Simple rate limiting (in production, use Redis or similar)
        if not hasattr(self, 'rate_limits'):
            self.rate_limits = {}
            
        if key in self.rate_limits:
            last_time = self.rate_limits[key]
            if current_time - last_time < 60:  # 1 minute
                return True
                
        self.rate_limits[key] = current_time
        return False
        
    def ip_in_range(self, ip, ip_range):
        # Simple IP range checking
        return ip.startswith(ip_range.split('/')[0])
        
    def route_to_honeypot(self, packet):
        self.logger.info(f"Routing suspicious traffic to honeypot: {packet[IP].src} -> {packet[TCP].dport}")
        self.log_traffic_event(packet, "HONEYPOT_ROUTE")
        return "HONEYPOT"
        
    def route_to_real_system(self, packet):
        self.logger.info(f"Routing legitimate traffic: {packet[IP].src} -> {packet[TCP].dport}")
        self.log_traffic_event(packet, "LEGITIMATE_ROUTE")
        return "LEGITIMATE"
        
    def route_to_decoy(self, packet):
        self.logger.info(f"Routing unknown traffic to decoy: {packet[IP].src} -> {packet[TCP].dport}")
        self.log_traffic_event(packet, "DECOY_ROUTE")
        return "DECOY"
        
    def log_traffic_event(self, packet, decision):
        event = {
            'timestamp': datetime.utcnow().isoformat(),
            'src_ip': packet[IP].src,
            'dst_port': packet[TCP].dport,
            'decision': decision,
            'protocol': 'TCP',
            'packet_size': len(packet)
        }
        
        # Add GeoIP data if available
        if self.geoip_reader:
            try:
                geo_data = self.geoip_reader.city(packet[IP].src)
                event['geoip'] = {
                    'country': geo_data.country.name,
                    'city': geo_data.city.name,
                    'latitude': geo_data.location.latitude,
                    'longitude': geo_data.location.longitude
                }
            except AddressNotFoundError:
                pass
                
        # Send to Elasticsearch (placeholder)
        self.send_to_elasticsearch(event)
        
    def send_to_elasticsearch(self, event):
        # Send event to Elasticsearch for analysis
        try:
            import requests
            response = requests.post(
                f"${ELASTICSEARCH_ENDPOINT}/honeywall-events/_doc/",
                json=event,
                timeout=5
            )
            if response.status_code == 201:
                self.logger.debug("Event logged to Elasticsearch")
        except Exception as e:
            self.logger.error(f"Failed to log to Elasticsearch: {e}")
            
    def start_monitoring(self):
        self.logger.info("Starting Honeywall traffic monitoring")
        
        # Start packet capture
        sniff(
            filter="tcp",
            prn=self.analyze_traffic,
            store=False
        )

if __name__ == "__main__":
    honeywall = Honeywall()
    honeywall.start_monitoring()
EOF

# Create legitimate IPs file
cat > legitimate_ips.txt << 'EOF'
# Add legitimate IP ranges here
# Example: 192.168.1.0/24
# Example: 10.0.0.0/8
EOF

# Download GeoIP database
wget -O GeoLite2-City.mmdb "https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz"
tar -xzf GeoLite2-City.tar.gz --strip-components=1 -C /opt/honeywall GeoLite2-City.mmdb

# Create systemd service
cat > /etc/systemd/system/honeywall.service << EOF
[Unit]
Description=Honeynet Honeywall Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/honeywall
ExecStart=/usr/bin/python3 /opt/honeywall/honeywall.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create log directory
mkdir -p /var/log/honeywall

# Start honeywall
systemctl enable honeywall
systemctl start honeywall

echo "Honeywall installed and configured!"
echo "Traffic analysis and routing active"
echo "Logs available at /var/log/honeywall/honeywall.log"
