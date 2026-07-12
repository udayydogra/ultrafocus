#!/bin/bash
# Run as root

echo "Setting up local Focus Web Server..."

# 1. Ensure directory exists
mkdir -p /home/uggi/Projects/ultrafocus

# 2. Generate SSL certificate for local HTTPS
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/ssl/private/focus_server.key \
  -out /etc/ssl/certs/focus_server.crt \
  -subj "/C=IN/ST=State/L=City/O=Focus/CN=localhost" 2>/dev/null

# 3. Create python server script
cat << 'EOF' > /home/uggi/Projects/ultrafocus/server.py
import http.server
import socketserver
import ssl
import threading

PORT_HTTP = 80
PORT_HTTPS = 443
DIRECTORY = "/home/uggi/Projects/ultrafocus"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    # Silence the logs so it doesn't spam syslog
    def log_message(self, format, *args):
        pass

def run_http():
    try:
        socketserver.TCPServer.allow_reuse_address = True
        with socketserver.TCPServer(("", PORT_HTTP), Handler) as httpd:
            httpd.serve_forever()
    except Exception as e:
        print(f"HTTP error: {e}")

def run_https():
    try:
        socketserver.TCPServer.allow_reuse_address = True
        with socketserver.TCPServer(("", PORT_HTTPS), Handler) as httpd:
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain(certfile="/etc/ssl/certs/focus_server.crt", keyfile="/etc/ssl/private/focus_server.key")
            httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
            httpd.serve_forever()
    except Exception as e:
        print(f"HTTPS error: {e}")

if __name__ == "__main__":
    threading.Thread(target=run_http, daemon=True).start()
    run_https()
EOF

# 4. Allow loopback traffic in iptables before the string matching blocks it
# This ensures that traffic directed to 127.0.0.1 (our local server) is accepted.
iptables -I OUTPUT 1 -o lo -j ACCEPT 2>/dev/null || true

# 5. Create systemd service to run the server in the background automatically
cat << 'EOF' > /etc/systemd/system/focus-server.service
[Unit]
Description=Focus Redirect Server (Motivational Page)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/uggi/Projects/ultrafocus
ExecStart=/usr/bin/python3 /home/uggi/Projects/ultrafocus/server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 6. Enable and start service
systemctl daemon-reload
systemctl enable focus-server
systemctl restart focus-server

echo "Focus server is successfully running!"
