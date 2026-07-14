#!/bin/bash
# UltraFocus Teardown Script
# Restores the computer to normal networking and stops all background services.

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Stopping UltraFocus services..."
systemctl stop focus-server 2>/dev/null
systemctl disable focus-server 2>/dev/null
systemctl stop focus-dns 2>/dev/null
systemctl disable focus-dns 2>/dev/null

echo "Cleaning /etc/hosts..."
# Delete any line with 127.0.0.1 that DOES NOT also contain localhost
sed -i '/127.0.0.1/!b; /localhost/b; d' /etc/hosts

echo "Removing iptables routing rules..."
# Save current nat table, filter out all our custom IPs, and restore it
iptables-save -t nat | grep -v '1.1.1.3' | grep -v '127.0.0.1:5353' | grep -v '0.0.0.0/8' | grep -v '1.1.1.1' | grep -v '8.8.8.8' | grep -v '127.0.0.1:80' | grep -v '127.0.0.1:443' | iptables-restore

# Save the clean iptables state so it persists on reboot
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
elif command -v iptables-save &> /dev/null; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null
fi

echo "All restrictions removed. The system is back to normal!"
