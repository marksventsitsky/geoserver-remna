# geo-serve

Зеркало `geoip.dat` / `geosite.dat` для нод Remnawave.

Контейнер на базе `nginx:alpine` раз в сутки тянет `geoip.dat` и `geosite.dat`
с GitHub-релизов RoscomVPN и отдаёт их по HTTP внутри сети `remnawave-network`.
Фронтовый `remnawave-nginx` терминирует TLS и проксирует запросы с публичного
домена на этот контейнер. Ноды забирают файлы уже с домена, а не напрямую
с GitHub — это убирает проблемы со скачиванием с GitHub на нодах.

```
GitHub releases ──(cron, curl)──> geo-serve ──> remnawave-nginx (TLS) ──> https://<домен>/geoip.dat
                                                                                      ▲
                                                                       ноды тянут раз в сутки
```

## Файлы

- `docker-compose.yml` — сервис `geo-serve`, подключён к внешней сети
  `remnawave-network`, данные в volume `geo-data`, порты наружу не публикуются.
- `entrypoint.sh` — при старте скачивает файлы и ставит cron на ежедневное
  обновление (04:00), затем запускает nginx.
- `update-geo.sh` — скачивание `geoip.dat` / `geosite.dat` с GitHub, атомарная
  замена через временный файл.
- `default.conf` — внутренний конфиг nginx раздающего контейнера; отдаёт `.dat`
  как `application/octet-stream`, есть `/healthz`.
- `geo.example.com.conf` — server-блок для `remnawave-nginx`: TLS + проксирование
  на `geo-serve`. Домен и пути к сертификату подставляются по месту.
- `node-update-geo.sh` — версия скрипта обновления для нод: тянет файлы с домена
  вместо GitHub.
- `geo-cert-deploy.sh` — хук для копирования обновлённого сертификата в каталог
  nginx и перезагрузки контейнера (для certbot; acme.sh делает это через
  `--reloadcmd`).

## Конфигурация

Реальный домен подставляется в `geo.example.com.conf` и `node-update-geo.sh`
вместо `geo.example.com`. Сертификат для домена выпускается отдельно и
монтируется в `remnawave-nginx`.
