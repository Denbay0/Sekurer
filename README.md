# Sekurer — AI Call Assistant MVP

## Backend milestone 1

### Что реализовано
- Скелет FastAPI backend (`backend/app`)
- SQLAlchemy модели + Alembic initial migration
- JWT auth: `register`, `login`, `me`
- Docker Compose для `api`, `postgres`, `redis`, `minio`

### Запуск
```bash
cd backend
cp .env.example .env
cd ..
docker compose up --build
```

### Миграции
```bash
docker compose exec api alembic upgrade head
```

### Проверка API
- Swagger: <http://localhost:8000/docs>
- Prefix: `/api/v1`
