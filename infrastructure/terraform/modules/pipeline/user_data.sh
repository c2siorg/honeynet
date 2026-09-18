#!/bin/bash
set -e

# Update system
yum update -y

# Install required packages
yum install -y python3 python3-pip docker git

# Install Python dependencies
pip3 install fastapi uvicorn redis kafka-python scapy elasticsearch pandas scikit-learn

# Create pipeline directory
mkdir -p /opt/pipeline
cd /opt/pipeline

# Create pipeline application
cat > pipeline_controller.py << 'EOF'
#!/usr/bin/env python3
import asyncio
import json
import time
import logging
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import redis
from kafka import KafkaProducer
import elasticsearch
from scapy.all import sniff, IP, TCP, UDP

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class AttackEvent:
    timestamp: str
    source_ip: str
    target_port: int
    attack_type: str
    honeypot_id: str
    severity: str
    metadata: Dict

class PipelineController:
    def __init__(self):
        self.redis_client = redis.Redis(host='${REDIS_ENDPOINT}', port=6379, decode_responses=True)
        self.kafka_producer = KafkaProducer(
            bootstrap_servers=['${KAFKA_ENDPOINT}'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        self.es_client = elasticsearch.Elasticsearch(['${ELASTICSEARCH_ENDPOINT}'])
        
        # ML model for attack classification
        self.attack_classifier = self.load_attack_classifier()
        
        # High-interaction honeypot pool
        self.high_interaction_pool = []
        self.active_high_interaction = {}
        
        # Cost optimization settings
        self.cost_threshold = 0.7  # Spawn high-interaction for high-value attacks
        self.max_high_interaction = 2  # Maximum concurrent high-interaction honeypots
        
    def load_attack_classifier(self):
        """Load ML model for attack classification"""
        # Placeholder for ML model
        # In production, load trained model for attack severity scoring
        return {
            'ssh_brute_force': 0.6,
            'web_attack': 0.8,
            'malware_upload': 0.9,
            'port_scan': 0.3
        }
    
    async def analyze_attack(self, event: AttackEvent) -> Dict:
        """Analyze attack and determine response"""
        # Classify attack severity
        severity_score = self.attack_classifier.get(event.attack_type, 0.5)
        
        # Check if high-interaction honeypot should be spawned
        should_spawn = severity_score >= self.cost_threshold
        
        # Get attack pattern from Redis cache
        cache_key = f"attack_pattern:{event.source_ip}"
        attack_history = self.redis_client.lrange(cache_key, 0, 9)
        
        analysis = {
            'event_id': f"evt_{int(time.time())}",
            'timestamp': event.timestamp,
            'severity_score': severity_score,
            'should_spawn_high_interaction': should_spawn,
            'attack_history_count': len(attack_history),
            'source_reputation': self.check_source_reputation(event.source_ip),
            'recommendation': 'HIGH_INTERACTION' if should_spawn else 'LOW_INTERACTION_ONLY'
        }
        
        return analysis
    
    def check_source_reputation(self, source_ip: str) -> Dict:
        """Check source IP reputation"""
        # Check against threat intelligence feeds
        # Placeholder implementation
        return {
            'is_known_attacker': source_ip in self.redis_client.smembers('known_attackers'),
            'attack_frequency': self.redis_client.get(f"attack_freq:{source_ip}") or 0,
            'geolocation': self.get_geolocation(source_ip)
        }
    
    def get_geolocation(self, source_ip: str) -> Dict:
        """Get geolocation data for IP"""
        # Placeholder for GeoIP lookup
        return {'country': 'Unknown', 'city': 'Unknown'}
    
    async def spawn_high_interaction_honeypot(self, attack_event: AttackEvent, analysis: Dict):
        """Spawn high-interaction honeypot for deep analysis"""
        if len(self.active_high_interaction) >= self.max_high_interaction:
            logger.warning("Maximum high-interaction honeypots reached")
            return None
        
        # Create honeypot instance
        honeypot_id = f"high_int_{int(time.time())}"
        
        # Send spawn event to Kafka
        spawn_event = {
            'event_type': 'HONEYPOT_SPAWN',
            'honeypot_type': 'HIGH_INTERACTION',
            'target_attack': attack_event.__dict__,
            'analysis': analysis,
            'honeypot_id': honeypot_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        self.kafka_producer.send('honeypot_events', spawn_event)
        
        # Track active honeypot
        self.active_high_interaction[honeypot_id] = {
            'spawn_time': time.time(),
            'target_attack': attack_event.source_ip,
            'ttl': 3600  # 1 hour lifetime
        }
        
        logger.info(f"Spawned high-interaction honeypot {honeypot_id}")
        return honeypot_id
    
    async def process_low_interaction_event(self, event: AttackEvent):
        """Process event from low-interaction honeypot"""
        # Cache attack pattern
        cache_key = f"attack_pattern:{event.source_ip}"
        self.redis_client.lpush(cache_key, json.dumps(event.__dict__))
        self.redis_client.expire(cache_key, 3600)  # 1 hour
        
        # Update attack frequency
        freq_key = f"attack_freq:{event.source_ip}"
        self.redis_client.incr(freq_key)
        self.redis_client.expire(freq_key, 86400)  # 24 hours
        
        # Analyze attack
        analysis = await self.analyze_attack(event)
        
        # Log to Elasticsearch
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': 'ATTACK_ANALYSIS',
            'source_ip': event.source_ip,
            'attack_type': event.attack_type,
            'severity_score': analysis['severity_score'],
            'recommendation': analysis['recommendation'],
            'honeypot_id': event.honeypot_id
        }
        
        self.es_client.index(
            index='honeynet-attacks',
            body=log_entry
        )
        
        # Spawn high-interaction if needed
        if analysis['should_spawn_high_interaction']:
            honeypot_id = await self.spawn_high_interaction_honeypot(event, analysis)
            if honeypot_id:
                # Send traffic redirection event
                redirect_event = {
                    'event_type': 'TRAFFIC_REDIRECT',
                    'source_ip': event.source_ip,
                    'target_port': event.target_port,
                    'original_honeypot': event.honeypot_id,
                    'new_honeypot': honeypot_id,
                    'timestamp': datetime.utcnow().isoformat()
                }
                self.kafka_producer.send('honeypot_events', redirect_event)
        
        return analysis
    
    def cleanup_expired_honeypots(self):
        """Clean up expired high-interaction honeypots"""
        current_time = time.time()
        expired_honeypots = []
        
        for honeypot_id, info in self.active_high_interaction.items():
            if current_time - info['spawn_time'] > info['ttl']:
                expired_honeypots.append(honeypot_id)
        
        for honeypot_id in expired_honeypots:
            # Send termination event
            terminate_event = {
                'event_type': 'HONEYPOT_TERMINATE',
                'honeypot_id': honeypot_id,
                'reason': 'TTL_EXPIRED',
                'timestamp': datetime.utcnow().isoformat()
            }
            self.kafka_producer.send('honeypot_events', terminate_event)
            
            del self.active_high_interaction[honeypot_id]
            logger.info(f"Terminated expired honeypot {honeypot_id}")

# FastAPI application
app = FastAPI(title="Honeynet Pipeline Controller")

# Global pipeline controller
pipeline = PipelineController()

@app.post("/attack-event")
async def handle_attack_event(event: Dict):
    """Handle attack event from low-interaction honeypots"""
    try:
        attack_event = AttackEvent(**event)
        analysis = await pipeline.process_low_interaction_event(attack_event)
        return JSONResponse(content=analysis)
    except Exception as e:
        logger.error(f"Error processing attack event: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/status")
async def get_pipeline_status():
    """Get pipeline status"""
    return {
        'active_high_interaction_honeypots': len(pipeline.active_high_interaction),
        'max_high_interaction': pipeline.max_high_interaction,
        'cost_threshold': pipeline.cost_threshold,
        'total_attacks_processed': pipeline.redis_client.get('total_attacks') or 0
    }

@app.post("/spawn-high-interaction")
async def manual_spawn(spawn_request: Dict):
    """Manually spawn high-interaction honeypot"""
    event = AttackEvent(**spawn_request['attack_event'])
    honeypot_id = await pipeline.spawn_high_interaction_honeypot(event, spawn_request.get('analysis', {}))
    return {'honeypot_id': honeypot_id}

if __name__ == "__main__":
    import uvicorn
    
    # Start cleanup task
    async def cleanup_task():
        while True:
            pipeline.cleanup_expired_honeypots()
            await asyncio.sleep(60)  # Check every minute
    
    # Run cleanup task in background
    loop = asyncio.get_event_loop()
    loop.create_task(cleanup_task())
    
    # Start API server
    uvicorn.run(app, host="0.0.0.0", port=8080)
EOF

# Create systemd service
cat > /etc/systemd/system/pipeline-controller.service << EOF
[Unit]
Description=Honeynet Pipeline Controller
After=network.target docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pipeline
ExecStart=/usr/bin/python3 /opt/pipeline/pipeline_controller.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start pipeline controller
systemctl enable pipeline-controller
systemctl start pipeline-controller

echo "Pipeline controller installed and running!"
echo "API endpoint: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Connected to Kafka at ${KAFKA_ENDPOINT}"
echo "Connected to Redis at ${REDIS_ENDPOINT}"
echo "Connected to Elasticsearch at ${ELASTICSEARCH_ENDPOINT}"
