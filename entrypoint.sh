#!/bin/sh
#
# Entrypoint контейнера geo-serve:
#   1. ставит curl/ca-certificates (busybox wget c TLS бывает капризным)
#   2. качает geo-файлы при старте
#   3. поднимает crond для ежедневного обновления
#   4. запускает nginx на переднем плане
#
set -e

apk add --no-cache curl ca-certificates >/dev/null 2>&1 || true

echo "[entrypoint] $(date '+%F %T') initial geo download..."
/usr/local/bin/update-geo.sh >> /var/log/geo-update.log 2>&1 || \
    echo "[entrypoint] initial download failed — будет повтор по cron"

# Ежедневно в 04:00
mkdir -p /etc/crontabs
echo "0 4 * * * /usr/local/bin/update-geo.sh >> /var/log/geo-update.log 2>&1" > /etc/crontabs/root
crond -b -l 8

exec nginx -g 'daemon off;'
