# Sekurer — AI Call Assistant MVP

## Backend Milestone 2

### Запуск
```bash
cp backend/.env.example backend/.env
docker compose up --build
```

### Миграции
```bash
docker compose exec api alembic upgrade head
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

## Smoke test

```bash
cp backend/.env.example backend/.env
docker compose up --build
docker compose exec api alembic upgrade head
bash scripts/smoke_test.sh
```

### Troubleshooting
- Если worker не обрабатывает задачи, проверьте: `docker compose logs worker`
- Если ошибка MinIO, проверьте консоль: `http://localhost:9001`
- Если звонок в `failed`, посмотрите `error_message`: `GET /api/v1/calls/{id}`

## Mock mode
Если `OPENAI_API_KEY=replace-me` или пустой, pipeline не падает и использует mock-обработку:
- создаётся transcript
- summary
- минимум 1 agreement
- минимум 1 task
- минимум 1 unclear point
