#!/bin/bash
# Nuclear Whitelist Setup Script
# Must be run as root

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Setting up Nuclear Whitelist..."

# 1. Create Systemd Service for our custom dnsmasq
cat <<EOF > /etc/systemd/system/focus-dns.service
[Unit]
Description=Focus Nuclear Whitelist DNS Proxy
After=network.target

[Service]
ExecStart=/usr/bin/dnsmasq -k -C $DIR/focus_dnsmasq.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable focus-dns
systemctl restart focus-dns

# 2. Cleanup old Cloudflare DNS Hijack rules from distraction_free.sh
iptables -t nat -D OUTPUT -p udp --dport 53 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null
iptables -t nat -D OUTPUT -p tcp --dport 53 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null

# 3. Apply New DNS Hijack (Redirect all DNS to local port 5353)
# We must exclude Cloudflare IPs so dnsmasq can reach upstream!
iptables -t nat -D OUTPUT -d 1.1.1.1 -p udp --dport 53 -j ACCEPT 2>/dev/null
iptables -t nat -A OUTPUT -d 1.1.1.1 -p udp --dport 53 -j ACCEPT

iptables -t nat -D OUTPUT -d 1.1.1.1 -p tcp --dport 53 -j ACCEPT 2>/dev/null
iptables -t nat -A OUTPUT -d 1.1.1.1 -p tcp --dport 53 -j ACCEPT

iptables -t nat -D OUTPUT -d 8.8.8.8 -p udp --dport 53 -j ACCEPT 2>/dev/null
iptables -t nat -A OUTPUT -d 8.8.8.8 -p udp --dport 53 -j ACCEPT

iptables -t nat -D OUTPUT -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:5353 2>/dev/null
iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:5353

iptables -t nat -D OUTPUT -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:5353 2>/dev/null
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:5353

# Save iptables rules
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
elif command -v iptables-save &> /dev/null; then
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null
fi

echo "Nuclear Whitelist Mode ACTIVE."
echo "Every website is now blocked except those in focus_dnsmasq.conf"
