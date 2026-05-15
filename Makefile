.PHONY: init up migrate smoke logs test down reset

init:
	@test -f backend/.env || cp backend/.env.example backend/.env

up:
	docker compose up --build -d

migrate:
	docker compose exec api alembic upgrade head

smoke:
	bash scripts/smoke_test.sh

logs:
	docker compose logs -f api worker

test:
	docker compose exec api pytest

down:
	docker compose down

reset:
	docker compose down -v
