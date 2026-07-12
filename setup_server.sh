#!/bin/bash
# Run as root

echo "Setting up local Focus Web Server..."

# Dynamically find where the script (and the project) is located
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# 1. Generate SSL certificate for local HTTPS (if not already done)
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/ssl/private/focus_server.key \
  -out /etc/ssl/certs/focus_server.crt \
  -subj "/C=IN/ST=State/L=City/O=Focus/CN=localhost" 2>/dev/null

# 2. Allow loopback traffic in iptables before the string matching blocks it
# This ensures that traffic directed to 127.0.0.1 (our local server) is accepted.
iptables -I OUTPUT 1 -o lo -j ACCEPT 2>/dev/null || true

# 3. Create systemd service to run the server in the background automatically
cat << EOF > /etc/systemd/system/focus-server.service
[Unit]
Description=UltraFocus Redirect Server (Motivational Page)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/python3 $PROJECT_DIR/server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 4. Enable and start service
systemctl daemon-reload
systemctl enable focus-server
systemctl restart focus-server

echo "UltraFocus server is successfully running in the background!"
