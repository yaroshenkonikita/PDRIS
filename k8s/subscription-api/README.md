# Subscription API — Kubernetes manifests

Манифесты для развёртывания Лабы №2 (`subscription_api/docker-compose.yml`) в Kubernetes.

## Состав
- Namespace `subscription-api`
- PostgreSQL 16: StatefulSet + Service `db`
- API (FastAPI): Deployment + Service `api` (NodePort 30080 -> 8000)

## Быстрый старт

1) Установить образ API (по умолчанию `docker.io/tokimikichika/subscription-api:latest`).

2) Запустить локальный кластер Kubernetes через Minikube (если ещё не запущен):

```bash
# установить minikube: https://minikube.sigs.k8s.io/
minikube start --driver=docker
kubectl config use-context minikube
```

3) Применить манифесты:

```bash
kubectl apply -k k8s/subscription-api
kubectl get pods -n subscription-api
```

4) Дождаться, пока все поды станут `Running` и `READY`.

5) Проверить доступность API:

```bash
# порт‑форвардинг
kubectl -n subscription-api port-forward svc/api 8000:8000 &
curl http://localhost:8000/health
```

5) Создать подписку:

```bash
curl -sS -X POST http://localhost:8000/subscriptions \
  -H 'Content-Type: application/json' \
  -d '{"email":"nikita@gmail.com","event_type":"order_created"}' | jq
```

