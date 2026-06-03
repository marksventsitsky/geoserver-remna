# geo-serve — раздача geoip.dat / geosite.dat по geo.example.com

Контейнер `geo-serve` раз в сутки (04:00) тянет `geoip.dat` и `geosite.dat`
с GitHub-релизов RoscomVPN и отдаёт их по HTTP внутри `remnawave-network`.
`remnawave-nginx` проксирует `https://geo.example.com/*` → `geo-serve:80`.
Ноды переключаются с GitHub на этот домен.

```
GitHub releases ──(cron 04:00, curl)──> geo-serve ──> remnawave-nginx (TLS) ──> https://geo.example.com/geoip.dat
                                                                                              ▲
                                                                          ноды тянут раз в сутки
```

## Деплой на сервере

### 0. DNS
A-запись `geo.example.com` → IP remnawave-сервера. Порт 80 открыт (для certbot).

### 1. Залить файлы
```bash
scp -r geo-serve root@SERVER:/opt/geo-serve
```

### 2. Поднять раздающий контейнер
```bash
cd /opt/geo-serve
docker compose up -d
docker logs geo-serve            # должно быть "OK geosite.dat / geoip.dat"
docker exec geo-serve ls -la /usr/share/nginx/html
```

### 3. Выпустить сертификат (certbot, standalone на порту 80)
```bash
apt-get install -y certbot           # если ещё нет
certbot certonly --standalone -d geo.example.com \
    --non-interactive --agree-tos -m admin@example.com

# скопировать в каталог nginx
cp /etc/letsencrypt/live/geo.example.com/fullchain.pem /opt/remnawave/nginx/geo_fullchain.pem
cp /etc/letsencrypt/live/geo.example.com/privkey.pem  /opt/remnawave/nginx/geo_privkey.key
```
> Если порт 80 закрыт извне — используй DNS-01:
> `certbot certonly --manual --preferred-challenges dns -d geo.example.com`

### 4. Подключить сертификат и server-блок к remnawave-nginx
В `/opt/remnawave/nginx/docker-compose.yml` в `volumes:` добавить:
```yaml
            - ./geo_fullchain.pem:/etc/nginx/ssl/geo_fullchain.pem:ro
            - ./geo_privkey.key:/etc/nginx/ssl/geo_privkey.key:ro
```
В `/opt/remnawave/nginx/nginx.conf` добавить содержимое `geo.example.com.conf`
(готовый server-блок).

Применить:
```bash
cd /opt/remnawave/nginx
docker compose up -d            # перемонтировать volumes (reload недостаточно для новых mount)
docker exec remnawave-nginx nginx -t
```

### 5. Проверка
```bash
curl -I https://geo.example.com/geoip.dat
curl -I https://geo.example.com/geosite.dat
curl     https://geo.example.com/healthz
```

### 6. Автопродление сертификата
```bash
cp /opt/geo-serve/geo-cert-deploy.sh /opt/remnawave/nginx/geo-cert-deploy.sh
chmod +x /opt/remnawave/nginx/geo-cert-deploy.sh
# проверить deploy-hook
certbot renew --dry-run --deploy-hook /opt/remnawave/nginx/geo-cert-deploy.sh
```
(systemd-таймер `certbot.timer` уже запускает renew; hook скопирует cert и сделает reload.)

### 7. Переключить ноды на домен
На каждой ноде заменить `/opt/remnanode/update-geo.sh` на `node-update-geo.sh`
(URL'ы уже указывают на geo.example.com), затем разово прогнать:
```bash
cp node-update-geo.sh /opt/remnanode/update-geo.sh
chmod +x /opt/remnanode/update-geo.sh
/opt/remnanode/update-geo.sh
tail /var/log/remnawave-geo-update.log
```
Cron на нодах уже настроен установщиком (`install-roscomvpn-geo.sh`, 04:00).

## Обслуживание
- Принудительно обновить файлы на сервере: `docker exec geo-serve /usr/local/bin/update-geo.sh`
- Лог обновлений: `docker exec geo-serve cat /var/log/geo-update.log`
