#!/bin/sh
#
# Скачивает geoip.dat и geosite.dat от RoscomVPN с GitHub в webroot.
# Запускается внутри контейнера geo-serve: один раз при старте и далее по cron.
#
set -u

WEBROOT="/usr/share/nginx/html"
GEOSITE_URL="https://github.com/hydraponique/roscomvpn-geosite/releases/latest/download/geosite.dat"
GEOIP_URL="https://github.com/hydraponique/roscomvpn-geoip/releases/latest/download/geoip.dat"

ts() { date '+%Y-%m-%d %H:%M:%S'; }

# dl <url> <output>
dl() {
    url="$1"; out="$2"; tmp="${out}.tmp"
    if curl -fsSL --retry 3 --retry-delay 5 -o "$tmp" "$url" && [ -s "$tmp" ]; then
        mv "$tmp" "$out"
        chmod 644 "$out"
        echo "$(ts) OK    $(basename "$out") ($(wc -c < "$out") bytes)"
        return 0
    fi
    rm -f "$tmp"
    echo "$(ts) ERROR $(basename "$out") <- $url"
    return 1
}

mkdir -p "$WEBROOT"

rc=0
dl "$GEOSITE_URL" "$WEBROOT/geosite.dat" || rc=1
dl "$GEOIP_URL"   "$WEBROOT/geoip.dat"   || rc=1
exit "$rc"
