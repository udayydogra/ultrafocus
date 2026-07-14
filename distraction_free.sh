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
    # Social Media
    "reddit.com" "www.reddit.com" "old.reddit.com"
    "youtube.com" "www.youtube.com" "m.youtube.com"
    "instagram.com" "www.instagram.com"
    "facebook.com" "www.facebook.com" "m.facebook.com"
    "x.com" "www.x.com" "twitter.com" "www.twitter.com"
    "tiktok.com" "www.tiktok.com"
    "pinterest.com" "www.pinterest.com"
    "snapchat.com" "www.snapchat.com"
    "tumblr.com" "www.tumblr.com"
    
    # Messaging
    "telegram.org" "web.telegram.org" "desktop.telegram.org" "t.me"
    "discord.com" "www.discord.com"

    # Streaming & OTT
    "netflix.com" "www.netflix.com"
    "primevideo.com" "www.primevideo.com"
    "hotstar.com" "www.hotstar.com"
    "sonyliv.com" "www.sonyliv.com"
    "jiotv.com" "www.jiotv.com"
    "zee5.com" "www.zee5.com"
    "jiocinema.com" "www.jiocinema.com"
    "hulu.com" "www.hulu.com"
    "disneyplus.com" "www.disneyplus.com"
    "hbomax.com" "www.hbomax.com"
    "crunchyroll.com" "www.crunchyroll.com"
    "twitch.tv" "www.twitch.tv"

    # Music
    "spotify.com" "www.spotify.com" "open.spotify.com"
    "soundcloud.com" "www.soundcloud.com"

    # Shopping
    "amazon.com" "www.amazon.com" "amazon.in" "www.amazon.in"
    "flipkart.com" "www.flipkart.com"
    "myntra.com" "www.myntra.com"
    "ebay.com" "www.ebay.com"
    "aliexpress.com" "www.aliexpress.com"
    "etsy.com" "www.etsy.com"
    "meesho.com" "www.meesho.com"
    "ajio.com" "www.ajio.com"

    # Gaming & Entertainment
    "steampowered.com" "www.steampowered.com" "store.steampowered.com"
    "epicgames.com" "www.epicgames.com"
    "roblox.com" "www.roblox.com"
    "ign.com" "www.ign.com"
    "gamespot.com" "www.gamespot.com"
    "kotaku.com" "www.kotaku.com"
    "9gag.com" "www.9gag.com"
    "4chan.org" "www.4chan.org"

    # News & Blogs
    "news.google.com" "bbc.com" "www.bbc.com" "cnn.com" "www.cnn.com"
    "nytimes.com" "www.nytimes.com"
    "theguardian.com" "www.theguardian.com"
    "wsj.com" "www.wsj.com"
    "washingtonpost.com" "www.washingtonpost.com"
    "buzzfeed.com" "www.buzzfeed.com"
    "ndtv.com" "www.ndtv.com"
    "indiatoday.in" "www.indiatoday.in"
    "timesofindia.indiatimes.com"
    "thehindu.com" "www.thehindu.com"
    "quora.com" "www.quora.com"
    "medium.com" "www.medium.com"
    "news.ycombinator.com"
    
    # Adult Content Base Strings
    "xhamster.com" "www.xhamster.com"
)

for domain in "${BLOCKLIST[@]}"; do
    if ! grep -q "[[:space:]]$domain$" /etc/hosts; then
        echo "127.0.0.1 $domain" >> /etc/hosts
    fi
done

# 2. Block all adult content using DNS & iptables
echo "Forcing all DNS queries through Cloudflare Family DNS (Blocks Adult Content)..."
iptables -t nat -D OUTPUT -p udp --dport 53 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null
iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 1.1.1.3:53

iptables -t nat -D OUTPUT -p tcp --dport 53 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 1.1.1.3:53

echo "Intercepting Cloudflare blocked IP (0.0.0.0) and redirecting to local motivational server..."
iptables -t nat -D OUTPUT -d 0.0.0.0/8 -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:80 2>/dev/null
iptables -t nat -A OUTPUT -d 0.0.0.0/8 -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:80

iptables -t nat -D OUTPUT -d 0.0.0.0/8 -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1:443 2>/dev/null
iptables -t nat -A OUTPUT -d 0.0.0.0/8 -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1:443


# (String matching removed due to extreme CPU bottlenecking on network packets)

# Save iptables rules so they persist across reboots (Debian/Ubuntu specific)
if command -v netfilter-persistent &> /dev/null; then
    echo "Saving iptables rules persistently..."
    netfilter-persistent save
elif command -v iptables-save &> /dev/null; then
    # Fallback to standard save (might not load automatically on boot depending on OS)
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || echo "Note: Could not automatically save iptables rules for next boot. You may need to install iptables-persistent."
fi

echo "Setup complete! Your laptop is now aggressively configured for distraction-free coding."
