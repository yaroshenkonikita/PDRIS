# Ansible lab: Nginx + Subscription API

Сборка демонстрирует развёртывание на «чистых машинах» (контейнерах) с Ansible:
- ansible-master — управляющий контейнер с Ansible
- nginx — чистый Ubuntu-контейнер; Ansible ставит и настраивает nginx как reverse-proxy
- app — чистый Ubuntu-контейнер; Ansible разворачивает Subscription API (FastAPI) и запускает через shell-скрипт
- db — PostgreSQL (вспомогательный контейнер)

Стэк поднимается одной сетью docker-compose. Ansible подключается к целевым контейнерам через connection=docker (без SSH).

Требования:
- Docker / Docker Compose

Быстрый старт:
1) Поднять инфраструктуру (контейнеры, сеть):

```
docker compose -f ansible-lab/docker-compose.yml up -d --build
```

2) Применить плейбуки (из ansible-контроллера):

```
docker compose -f ansible-lab/docker-compose.yml exec ansible ansible-playbook -i /ansible/inventory/hosts.ini /ansible/playbooks/site.yml
```

3) Проверка работоспособности:

```
# Nginx проксирует на приложение
curl http://localhost:8080/health

# Создание подписки
curl -sS -X POST http://localhost:8080/subscriptions -H 'Content-Type: application/json' -d '{"email":"yaroshenko@gmail.com","event_type":"order_created"}' | jq

# Список подписок
curl -sS http://localhost:8080/subscriptions | jq

# Состояние контейнеров
docker compose -f ansible-lab/docker-compose.yml ps
```

Приложение:
- Исходники API расположены в `subscription_api/` (в корне репозитория). Ansible копирует их в контейнер `app` и запускает через `run_app.sh`.

Примечания:
- Все целевые контейнеры — Ubuntu и стартуют «пустыми» (команда `sleep infinity`).
- Ansible ставит все зависимости, раскладывает конфиги и запускает процессы.
- БД Postgres поднимается отдельно контейнером `db` (вспомогательный сервис).
