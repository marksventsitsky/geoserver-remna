#!/bin/sh
#
# Entrypoint контейнера geo-serve:
#   1. поднимает nginx ПЕРВЫМ (порт 80 доступен всегда)
#   2. сразу запускает crond (НЕ ждёт скачивание — иначе при таймаутах GitHub
#      crond стартовал бы только через минуты)
#   3. первичное скачивание уходит в ФОН
#
# nginx — в фоне, ждём его в конце через wait.

nginx -g 'daemon off;' &
NGINX_PID=$!

# Ежедневно в 04:00. Каталог crontab задаём явно (-c), чтобы не зависеть от
# наличия симлинка /var/spool/cron/crontabs -> /etc/crontabs в образе.
mkdir -p /etc/crontabs
echo "0 4 * * * /usr/local/bin/update-geo.sh >> /var/log/geo-update.log 2>&1" > /etc/crontabs/root
crond -b -l 8 -c /etc/crontabs -L /var/log/cron.log

# Первичное скачивание — в фоне, чтобы не блокировать ни nginx, ни crond.
{
    echo "[entrypoint] $(date '+%F %T') initial geo download..."
    /usr/local/bin/update-geo.sh || echo "[entrypoint] initial download failed — повтор по cron"
} >> /var/log/geo-update.log 2>&1 &

wait "$NGINX_PID"
