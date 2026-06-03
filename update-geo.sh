#!/bin/sh
#
# Скачивает geoip.dat и geosite.dat от RoscomVPN с GitHub в webroot.
# Использует busybox wget (есть в nginx:alpine, TLS поддерживается).
# Запускается внутри контейнера geo-serve: один раз при старте и далее по cron.
#
set -u

WEBROOT="/usr/share/nginx/html"
GEOSITE_URL="https://github.com/hydraponique/roscomvpn-geosite/releases/latest/download/geosite.dat"
GEOIP_URL="https://github.com/hydraponique/roscomvpn-geoip/releases/latest/download/geoip.dat"

ts() { date '+%Y-%m-%d %H:%M:%S'; }

# dl <url> <output> — до 3 попыток, busybox wget сам идёт по редиректам GitHub
dl() {
    url="$1"; out="$2"; tmp="${out}.tmp"
    n=0
    while [ "$n" -lt 3 ]; do
        if wget -q -T 30 -O "$tmp" "$url" && [ -s "$tmp" ]; then
            mv "$tmp" "$out"
            chmod 644 "$out"
            echo "$(ts) OK    $(basename "$out") ($(wc -c < "$out") bytes)"
            return 0
        fi
        n=$((n + 1))
        sleep 3
    done
    rm -f "$tmp"
    echo "$(ts) ERROR $(basename "$out") <- $url"
    return 1
}

mkdir -p "$WEBROOT"

rc=0
dl "$GEOSITE_URL" "$WEBROOT/geosite.dat" || rc=1
dl "$GEOIP_URL"   "$WEBROOT/geoip.dat"   || rc=1
exit "$rc"
