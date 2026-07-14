import http.server
import socketserver
import ssl
import threading
import os

PORT_HTTP = 80
PORT_HTTPS = 443

# Dynamically get the directory where server.py is located
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    # Silence the logs so it doesn't spam syslog
    def log_message(self, format, *args):
        pass

def run_http():
    try:
        socketserver.ThreadingTCPServer.allow_reuse_address = True
        with socketserver.ThreadingTCPServer(("", PORT_HTTP), Handler) as httpd:
            httpd.serve_forever()
    except Exception as e:
        print(f"HTTP error: {e}")

def run_https():
    try:
        socketserver.ThreadingTCPServer.allow_reuse_address = True
        with socketserver.ThreadingTCPServer(("", PORT_HTTPS), Handler) as httpd:
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain(certfile="/etc/ssl/certs/focus_server.crt", keyfile="/etc/ssl/private/focus_server.key")
            httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
            httpd.serve_forever()
    except Exception as e:
        print(f"HTTPS error: {e}")

if __name__ == "__main__":
    threading.Thread(target=run_http, daemon=True).start()
    run_https()
