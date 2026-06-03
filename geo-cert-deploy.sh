#!/bin/bash
#
# certbot deploy-hook: копирует обновлённый сертификат geo.example.com
# в каталог remnawave-nginx и перезагружает nginx внутри контейнера.
#
set -euo pipefail

LIVE="/etc/letsencrypt/live/geo.example.com"
DEST="/opt/remnawave/nginx"

cp "${LIVE}/fullchain.pem" "${DEST}/geo_fullchain.pem"
cp "${LIVE}/privkey.pem"   "${DEST}/geo_privkey.key"

docker exec remnawave-nginx nginx -s reload
echo "geo.example.com cert deployed & nginx reloaded"
