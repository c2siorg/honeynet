#!/bin/bash
set -e
 
# Update system
yum update -y
 
# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
 
# Install git
yum install -y git
 
# Create honeypot directory
mkdir -p /opt/honeypot
cd /opt/honeypot
 
# Clone Cowrie
git clone https://github.com/cowrie/cowrie.git
cd cowrie
 
# Install Python dependencies
yum install -y python3 python3-pip
pip3 install -r requirements.txt
 
# Create cowrie user
useradd -m -s /bin/bash cowrie
chown -R cowrie:cowrie /opt/honeypot/cowrie
 
# Copy configuration template
cp etc/cowrie.cfg.dist etc/cowrie.cfg
 
# Configure Cowrie to listen on port 2222
sed -i 's/ssh_port = 2222/ssh_port = 2222/' etc/cowrie.cfg
sed -i 's/telnet_port = 2223/telnet_port = 2223/' etc/cowrie.cfg
 
# Enable JSON output
sed -i 's/\[output_json\]/\[output_json\]/' etc/cowrie.cfg
sed -i 's/# enabled = false/enabled = true/' etc/cowrie.cfg
 
# Create log directory
mkdir -p /opt/honeypot/cowrie/log
chown cowrie:cowrie /opt/honeypot/cowrie/log
 
# Create systemd service
cat > /etc/systemd/system/cowrie.service << EOF
[Unit]
Description=Cowrie Honeypot
After=network.target docker.service
 
[Service]
Type=simple
User=cowrie
WorkingDirectory=/opt/honeypot/cowrie
ExecStart=/usr/bin/python3 /opt/honeypot/cowrie/bin/cowrie start
Restart=always
RestartSec=10
 
[Install]
WantedBy=multi-user.target
EOF
 
# Enable and start Cowrie
systemctl daemon-reload
systemctl enable cowrie
systemctl start cowrie
 
# Configure firewall
firewall-cmd --permanent --add-port=2222/tcp
firewall-cmd --permanent --add-port=2223/tcp
firewall-cmd --reload
 
echo "Cowrie honeypot installed and configured!"
echo "SSH honeypot listening on port 2222"
echo "Telnet honeypot listening on port 2223"
echo "Logs available at /opt/honeypot/cowrie/log/"
