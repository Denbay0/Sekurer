# Sekurer — AI Call Assistant MVP

## Backend Milestone 2

### Обязательная подготовка env
```bash
cp backend/.env.example backend/.env
```

> `docker-compose.yml` использует `env_file: backend/.env`, поэтому этот шаг обязателен перед любым запуском.

### Запуск
```bash
docker compose up --build -d
```

### Миграции
```bash
docker compose exec api alembic upgrade head
```

### Smoke test
```bash
bash scripts/smoke_test.sh
```

### Полный quickstart
```bash
cp backend/.env.example backend/.env
docker compose up --build -d
docker compose exec api alembic upgrade head
bash scripts/smoke_test.sh
```

### Требования для smoke test
- Нужны `curl` и `jq` (скрипт проверяет оба).

### Тесты
```bash
docker compose exec api pytest
```

### Логи
```bash
docker compose logs -f api
docker compose logs -f worker
```

### Остановка
```bash
docker compose down
```

### Полная очистка данных
```bash
docker compose down -v
```

### Полезные URL
- Health: `http://localhost:8000/health`
- Docs: `http://localhost:8000/docs`

## API flow (curl)

### 1) Регистрация
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@example.com","password":"demo12345","name":"Demo"}'
```

### 2) Логин
```bash
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@example.com","password":"demo12345"}' | jq -r .access_token)
```

### 3) Upload аудио
```bash
curl -X POST http://localhost:8000/api/v1/calls/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@./sample.mp3" \
  -F "title=Call with client" \
  -F "contact_name=Client" \
  -F "phone_number=+123456789"
```

### 4) Список звонков
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/calls
```

### 5) Детали звонка (статус/транскрипт/summary)
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/calls/{CALL_ID}
```

### 6) Список задач
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/tasks
```

### Troubleshooting
- Если worker не обрабатывает задачи, проверьте: `docker compose logs -f worker`
- Если ошибка MinIO, проверьте консоль: `http://localhost:9001`
- Если звонок в `failed`, посмотрите `error_message`: `GET /api/v1/calls/{id}`

## Mock mode
Если `OPENAI_API_KEY=replace-me` или пустой, pipeline не падает и использует mock-обработку:
- создаётся transcript
- summary
- минимум 1 agreement
- минимум 1 task
- минимум 1 unclear point

## Mobile development

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Для реального телефона:

```bash
flutter run --dart-define=API_BASE_URL=http://<LAN_IP>:8000
```

Backend должен быть запущен:

```bash
make init
make up
make migrate
make smoke
```

## Mobile Milestone 1.1

```bash
cd mobile
flutter pub get
flutter analyze
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Пояснения по API URL:
- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://localhost:8000`
- Реальный телефон: `http://<LAN_IP>:8000`

Перед запуском mobile backend должен быть поднят:

```bash
make init
make up
make migrate
make smoke
```
