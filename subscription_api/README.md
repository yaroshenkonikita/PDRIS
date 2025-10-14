# Subscription API (FastAPI + Postgres)

Простое REST‑приложение на FastAPI для подписок: сохраняет `email` и `event_type` в БД. Поднимается вместе с PostgreSQL через `docker-compose`. Образ API можно собрать Dockerfile и отправить в docker registry.

## Состав
- API: FastAPI + SQLAlchemy, эндпоинты:
  - `POST /subscriptions` — создать подписку `{ email, event_type }` (идемпотентно)
  - `GET /subscriptions` — список (фильтры `email`, `event_type`)
  - `GET /subscriptions/{id}` — получить по id
  - `GET /health` — проверка живости
- БД: PostgreSQL 16

## Быстрый старт (compose)
1) Запустить сервисы:

```bash
docker compose pull && \
docker compose up -d
```

2) Проверить:

```bash
curl http://localhost:8000/health
```

3) Создать подписку:

```bash
curl -sS -X POST http://localhost:8000/subscriptions \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","event_type":"order_created"}' 2>/dev/null | jq
```

4) Список подписок:

```bash
curl -sS http://localhost:8000/subscriptions 2>/dev/null | jq
```

5) Проверить базу:

```bash
sudo docker exec -it subscription_db psql -U app -d subscriptions -c "select * from subscriptions"
```
