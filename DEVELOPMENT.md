# DEVELOPMENT

## Backend architecture
- `api` (FastAPI): REST endpoints, auth, upload, CRUD/list APIs.
- `worker` (Celery): async обработка звонков (`process_call`).
- `postgres`: хранение пользователей, звонков, задач, agreements, calendar items.
- `redis`: broker/result backend для Celery.
- `minio`: хранение аудиофайлов.

## Pipeline обработки
1. `POST /api/v1/calls/upload` сохраняет файл в MinIO и создаёт запись звонка со статусом `uploaded`.
2. API отправляет Celery-задачу `process_call`.
3. Worker обновляет статус `uploaded -> transcribing -> analyzing -> ready`.
4. При ошибке worker выставляет `failed` и сохраняет `error_message`.

## Mock mode
Если `OPENAI_API_KEY` пустой или `replace-me`, AIService работает в mock-режиме:
- транскрипция и анализ генерируются локально;
- pipeline не зависит от внешнего OpenAI API.

## Как включить реальный OpenAI API
1. Откройте `backend/.env`.
2. Укажите валидный `OPENAI_API_KEY`.
3. Перезапустите сервисы:
   - `docker compose down`
   - `docker compose up --build -d`

## Где смотреть ошибки обработки
- API: `docker compose logs -f api`
- Worker: `docker compose logs -f worker`
- Детали конкретного звонка: `GET /api/v1/calls/{call_id}` (`status`, `error_message`).

## Что делать, если `call.status = failed`
1. Получить детали звонка через `GET /api/v1/calls/{call_id}`.
2. Проверить `error_message`.
3. Проверить логи worker и api.
4. Исправить причину (например MinIO/Redis/DB/env).
5. Запустить повторно: `POST /api/v1/calls/{call_id}/retry`.

## Что делать, если worker не обрабатывает задачи
1. Проверить, что сервис worker запущен: `docker compose ps`.
2. Проверить логи worker на ошибки импорта/регистрации задач: `docker compose logs -f worker`.
3. Убедиться, что Redis доступен и переменные окружения одинаковы у `api` и `worker`.
4. Выполнить новый upload и проверить смену статусов.
