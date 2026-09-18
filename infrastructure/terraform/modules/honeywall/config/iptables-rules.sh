#!/bin/bash
# Honeywall iptables configuration

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Clear existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# NAT for honeypot traffic
iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination ${HONEYPOT_PRIVATE_IP}:2222
iptables -t nat -A PREROUTING -p tcp --dport 2223 -j DNAT --to-destination ${HONEYPOT_PRIVATE_IP}:2223

# Log suspicious traffic
iptables -A FORWARD -p tcp --dport 22 -j LOG --log-prefix "SUSPICIOUS_SSH: "
iptables -A FORWARD -p tcp --dport 23 -j LOG --log-prefix "SUSPICIOUS_TELNET: "

# Rate limiting
iptables -A INPUT -p tcp --dport 22 -m limit --limit 10/minute --limit-burst 5 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP

# Save rules
iptables-save > /etc/iptables/rules.v4
