#!/bin/bash
#
# Версия update-geo.sh для НОД Remnawave: тянет geo-файлы с geo.example.com
# (а не напрямую с GitHub). Кладётся на ноду как /opt/remnanode/update-geo.sh
# и вызывается по cron (как в install-roscomvpn-geo.sh).
#
set -euo pipefail

GEO_DIR="/var/lib/remnanode"
COMPOSE_DIR="/opt/remnanode"
CONTAINER_NAME="remnanode"
GEOSITE_URL="https://geo.example.com/geosite.dat"
GEOIP_URL="https://geo.example.com/geoip.dat"
LOG_FILE="/var/log/remnawave-geo-update.log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
log() { echo "[${TIMESTAMP}] $1" >> "${LOG_FILE}"; }

if ! wget -q --spider "${GEOSITE_URL}" 2>/dev/null; then
    log "ERROR: geo.example.com недоступен, пропускаю обновление"
    exit 1
fi

UPDATED=false

update_one() {
    name="$1"; url="$2"; dest="${GEO_DIR}/${name}"
    old=""
    [[ -f "$dest" ]] && old=$(md5sum "$dest" | cut -d' ' -f1)
    wget -q -O "${dest}.tmp" "$url"
    new=$(md5sum "${dest}.tmp" | cut -d' ' -f1)
    if [[ "$old" != "$new" ]]; then
        mv "${dest}.tmp" "$dest"; chmod 644 "$dest"
        log "OK: ${name} обновлён (${new})"
        UPDATED=true
    else
        rm -f "${dest}.tmp"
        log "SKIP: ${name} не изменился"
    fi
}

update_one "geosite.dat" "$GEOSITE_URL"
update_one "geoip.dat"   "$GEOIP_URL"

if [[ "$UPDATED" == "true" ]]; then
    cd "$COMPOSE_DIR"
    docker compose restart "$CONTAINER_NAME" 2>>"$LOG_FILE" || \
    docker-compose restart "$CONTAINER_NAME" 2>>"$LOG_FILE" || true
    log "OK: контейнер ${CONTAINER_NAME} перезапущен"
fi
