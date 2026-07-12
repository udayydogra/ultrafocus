#!/bin/bash
# Must be run as root

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., sudo bash distraction_free.sh)"
  exit 1
fi

echo "Setting up a distraction-free coding environment..."

# 1. Block specific distractions via /etc/hosts
echo "Blocking specific sites in /etc/hosts..."
BLOCKLIST=(
    "reddit.com" "www.reddit.com" "old.reddit.com"
    "youtube.com" "www.youtube.com" "m.youtube.com"
    "instagram.com" "www.instagram.com"
    "facebook.com" "www.facebook.com" "m.facebook.com"
    "xhamster.com" "www.xhamster.com"
    "netflix.com" "www.netflix.com"
    "primevideo.com" "www.primevideo.com"
    "hotstar.com" "www.hotstar.com"
    "sonyliv.com" "www.sonyliv.com"
    "jiotv.com" "www.jiotv.com"
    "zee5.com" "www.zee5.com"
    "jiocinema.com" "www.jiocinema.com"
    "telegram.org" "web.telegram.org" "desktop.telegram.org" "t.me"
    "x.com" "www.x.com" "twitter.com" "www.twitter.com"
    "tiktok.com" "www.tiktok.com"
    "pinterest.com" "www.pinterest.com"
    "news.google.com" "bbc.com" "www.bbc.com" "cnn.com" "www.cnn.com"
    "quora.com" "www.quora.com"
    "medium.com" "www.medium.com"
    "news.ycombinator.com"
    "amazon.com" "www.amazon.com" "amazon.in" "www.amazon.in"
    "flipkart.com" "www.flipkart.com"
    "myntra.com" "www.myntra.com"
    "discord.com" "www.discord.com"
    "twitch.tv" "www.twitch.tv"
    "steampowered.com" "www.steampowered.com"
)

for domain in "${BLOCKLIST[@]}"; do
    if ! grep -q "[[:space:]]$domain$" /etc/hosts; then
        echo "127.0.0.1 $domain" >> /etc/hosts
    fi
done

# 2. Block all adult content using DNS & iptables
# It is practically impossible to block every porn site manually using iptables strings or IPs.
# The most robust way is to force all DNS queries to Cloudflare's Family DNS (1.1.1.3), 
# which automatically blocks malware and adult content.
echo "Forcing all DNS queries through Cloudflare Family DNS (Blocks Adult Content)..."
iptables -t nat -D OUTPUT -p udp --dport 53 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null
iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 1.1.1.3:53

iptables -t nat -D OUTPUT -p tcp --dport 53 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 1.1.1.3:53

# 3. iptables String Matching for requested specific strings (SNI / HTTP blocking)
# This will forcefully drop any connections that contain these strings in the packets.
echo "Adding iptables string-matching rules for aggressive blocking..."
STRINGS_TO_BLOCK=(
    "reddit.com"
    "youtube.com"
    "instagram.com"
    "facebook.com"
    "xhamster"
    "netflix.com"
    "primevideo.com"
    "hotstar.com"
    "sonyliv.com"
    "jiotv.com"
    "zee5.com"
    "jiocinema.com"
    "telegram"
    "t.me"
    "twitter.com"
    "x.com"
    "tiktok.com"
    "pinterest.com"
    "bbc.com"
    "cnn.com"
    "quora.com"
    "medium.com"
    "ycombinator.com"
    "amazon.com"
    "amazon.in"
    "flipkart.com"
    "myntra.com"
    "discord.com"
    "twitch.tv"
    "steampowered.com"
)

for str in "${STRINGS_TO_BLOCK[@]}"; do
    # Remove rule if it exists to avoid duplicates
    iptables -D OUTPUT -p tcp -m string --string "$str" --algo bm -j REJECT 2>/dev/null
    # Add the rule
    iptables -A OUTPUT -p tcp -m string --string "$str" --algo bm -j REJECT
done

# Save iptables rules so they persist across reboots (Debian/Ubuntu specific)
if command -v netfilter-persistent &> /dev/null; then
    echo "Saving iptables rules persistently..."
    netfilter-persistent save
elif command -v iptables-save &> /dev/null; then
    # Fallback to standard save (might not load automatically on boot depending on OS)
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || echo "Note: Could not automatically save iptables rules for next boot. You may need to install iptables-persistent."
fi

echo "Setup complete! Your laptop is now configured for distraction-free coding."
