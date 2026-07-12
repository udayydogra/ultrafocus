#!/bin/bash
# Run as root

echo "Fixing SSL Certificate for Chrome..."

# Get the actual user's home directory
USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")

# Install certutil to manage Chrome's certificate database
# Install nss for certutil
pacman -Sy --noconfirm nss

# 1. Create a config file for OpenSSL with ALL domains
cat << 'EOF' > /tmp/san.cnf
[req]
default_bits = 2048
prompt = no
default_md = sha256
x509_extensions = v3_req
distinguished_name = dn

[dn]
C = IN
ST = State
L = City
O = Focus
CN = FocusRoot

[v3_req]
subjectAltName = @alt_names
basicConstraints = CA:TRUE

[alt_names]
DNS.1 = reddit.com
DNS.2 = www.reddit.com
DNS.3 = old.reddit.com
DNS.4 = youtube.com
DNS.5 = www.youtube.com
DNS.6 = m.youtube.com
DNS.7 = instagram.com
DNS.8 = www.instagram.com
DNS.9 = facebook.com
DNS.10 = www.facebook.com
DNS.11 = m.facebook.com
DNS.12 = xhamster.com
DNS.13 = www.xhamster.com
DNS.14 = netflix.com
DNS.15 = www.netflix.com
DNS.16 = primevideo.com
DNS.17 = www.primevideo.com
DNS.18 = hotstar.com
DNS.19 = www.hotstar.com
DNS.20 = sonyliv.com
DNS.21 = www.sonyliv.com
DNS.22 = jiotv.com
DNS.23 = www.jiotv.com
DNS.24 = zee5.com
DNS.25 = www.zee5.com
DNS.26 = jiocinema.com
DNS.27 = www.jiocinema.com
DNS.28 = telegram.org
DNS.29 = web.telegram.org
DNS.30 = desktop.telegram.org
DNS.31 = t.me
DNS.32 = x.com
DNS.33 = www.x.com
DNS.34 = twitter.com
DNS.35 = www.twitter.com
DNS.36 = tiktok.com
DNS.37 = www.tiktok.com
DNS.38 = pinterest.com
DNS.39 = www.pinterest.com
DNS.40 = news.google.com
DNS.41 = bbc.com
DNS.42 = www.bbc.com
DNS.43 = cnn.com
DNS.44 = www.cnn.com
DNS.45 = quora.com
DNS.46 = www.quora.com
DNS.47 = medium.com
DNS.48 = www.medium.com
DNS.49 = news.ycombinator.com
DNS.50 = amazon.com
DNS.51 = www.amazon.com
DNS.52 = amazon.in
DNS.53 = www.amazon.in
DNS.54 = flipkart.com
DNS.55 = www.flipkart.com
DNS.56 = myntra.com
DNS.57 = www.myntra.com
DNS.58 = discord.com
DNS.59 = www.discord.com
DNS.60 = twitch.tv
DNS.61 = www.twitch.tv
DNS.62 = steampowered.com
DNS.63 = www.steampowered.com
DNS.64 = localhost
EOF

# 2. Generate the cert using the config
openssl req -new -x509 -nodes -days 365 -keyout /etc/ssl/private/focus_server.key -out /etc/ssl/certs/focus_server.crt -config /tmp/san.cnf 2>/dev/null

# 3. Add to system trust store (Arch Linux)
cp /etc/ssl/certs/focus_server.crt /etc/ca-certificates/trust-source/anchors/focus_server.crt
trust extract-compat > /dev/null 2>&1

# 4. Add to Chrome/Edge NSS DB
if [ -d "$USER_HOME/.pki/nssdb" ]; then
    # Delete old cert if exists, then add new one
    certutil -d sql:$USER_HOME/.pki/nssdb -D -n "FocusLocalhost" 2>/dev/null || true
    certutil -d sql:$USER_HOME/.pki/nssdb -A -t "C,," -n "FocusLocalhost" -i /etc/ssl/certs/focus_server.crt
else
    mkdir -p "$USER_HOME/.pki/nssdb"
    certutil -d sql:$USER_HOME/.pki/nssdb -N --empty-password
    certutil -d sql:$USER_HOME/.pki/nssdb -A -t "C,," -n "FocusLocalhost" -i /etc/ssl/certs/focus_server.crt
fi

# Ensure correct permissions
chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/.pki"

# 5. Restart the server
systemctl restart focus-server

echo "Success! The certificate error is fixed. Refresh the page in Chrome!"
