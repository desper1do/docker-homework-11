# docker-homework-11

Персональный контейнерный стенд из двух Docker-контейнеров (без Docker Compose).
Вариант **N = 11**, внешний порт **8011**, персональный идентификатор **cd6ac69c**.

## Состав

- `frontend` — nginx со стартовой страницей; публикуется на хост (`8011 -> 80`), запросы `/api` передаёт в backend по сетевому alias `backend`.
- `backend` — Python HTTP-сервис (стандартная библиотека); порт на хост не публикуется. Читает изменяемый файл `/data/message.txt` из Docker volume.
- Сеть `docker-homework-11` (пользовательская bridge), volume `docker-homework-11-data`.

## Структура

```text
docker-homework-11/
├── backend/        Dockerfile, server.py
├── frontend/       Dockerfile, nginx.conf, index.html
├── scripts/        start.sh, stop.sh
├── project.env     вариант, порт, персональный идентификатор
├── .dockerignore
├── README.md
└── REPORT.md
```

## Требования

Docker Engine (проверено на 29.2.1), bash, curl. Порт 8011 на хосте должен быть свободен.

## Запуск

```bash
chmod +x scripts/start.sh scripts/stop.sh
./scripts/start.sh
```

Скрипт создаёт сеть и volume (если их нет), собирает образы `docker-homework-11-backend:11` и `docker-homework-11-frontend:11`, пересоздаёт контейнеры с лимитами ресурсов и ждёт состояния `healthy`. Повторный запуск безопасен, данные в volume сохраняются.

## Проверка

```bash
curl http://localhost:8011/
curl http://localhost:8011/api
docker ps
docker network inspect docker-homework-11
docker stats --no-stream
```

Backend не опубликован на хост:

```bash
docker port docker-homework-11-backend      # пустой вывод
curl -m 3 http://localhost:8000/            # не отвечает
```

Лимиты и healthcheck:

```bash
docker inspect -f 'NanoCpus={{.HostConfig.NanoCpus}} Memory={{.HostConfig.Memory}}' docker-homework-11-backend
docker inspect -f '{{.State.Health.Status}}' docker-homework-11-backend docker-homework-11-frontend
```

Данные переживают пересоздание backend:

```bash
docker exec docker-homework-11-backend sh -c 'echo "новое сообщение" > /data/message.txt'
docker rm -f docker-homework-11-backend
./scripts/start.sh
curl http://localhost:8011/api     # message_from_volume содержит новое сообщение, hostname другой
```

## Остановка

```bash
./scripts/stop.sh            # удаляет контейнеры, volume и сеть сохраняются
./scripts/stop.sh --purge    # дополнительно удаляет volume и сеть
```

## Воспроизведение персональной неисправности (N % 4 = 3)

Неверный внутренний порт frontend: контейнер публикуется на `8080`, где nginx не слушает.

```bash
FRONTEND_CONTAINER_PORT=8080 ./scripts/start.sh   # внести неисправность
./scripts/start.sh                                # исправить (по умолчанию 80)
```

Подробное расследование — в `REPORT.md`.