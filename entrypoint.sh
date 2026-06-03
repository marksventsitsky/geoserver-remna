#!/bin/sh
#
# Entrypoint контейнера geo-serve:
#   1. поднимает nginx ПЕРВЫМ (порт 80 доступен всегда, даже если скачивание упадёт)
#   2. качает geo-файлы (busybox wget, без apk — репозитории Alpine могут быть недоступны)
#   3. ставит crond на ежедневное обновление
#
# nginx — в фоне, ждём его в конце через wait.

nginx -g 'daemon off;' &
NGINX_PID=$!

echo "[entrypoint] $(date '+%F %T') initial geo download..."
/usr/local/bin/update-geo.sh >> /var/log/geo-update.log 2>&1 || \
    echo "[entrypoint] initial download failed — повтор по cron"

# Ежедневно в 04:00
mkdir -p /etc/crontabs
echo "0 4 * * * /usr/local/bin/update-geo.sh >> /var/log/geo-update.log 2>&1" > /etc/crontabs/root
crond -b -l 8

wait "$NGINX_PID"
