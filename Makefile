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

mobile-apk-debug:
	cd mobile && flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000

mobile-apk-release:
	cd mobile && flutter build apk --release --dart-define=API_BASE_URL=http://$${API_BASE_URL}
