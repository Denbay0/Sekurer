import logging
import time
from collections.abc import Callable

import redis
from sqlalchemy import text

from app.core.config import settings
from app.db.session import engine
from app.services.storage_service import StorageService

logger = logging.getLogger(__name__)


def _retry_check(name: str, check: Callable[[], None]) -> None:
    last_error: Exception | None = None

    for attempt in range(1, settings.service_check_attempts + 1):
        try:
            check()
            logger.info("%s connected successfully", name)
            return
        except Exception as exc:
            last_error = exc
            logger.warning("%s connection check failed on attempt %s: %s", name, attempt, exc)
            if attempt < settings.service_check_attempts:
                time.sleep(settings.service_check_delay_seconds)

    raise RuntimeError(f"{name} connection failed after {settings.service_check_attempts} attempts") from last_error


def check_postgres() -> None:
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))


def check_redis() -> None:
    client = redis.Redis.from_url(settings.redis_url, socket_connect_timeout=3, socket_timeout=3)
    client.ping()


def check_minio() -> None:
    StorageService().ensure_bucket_exists()


def check_required_services() -> None:
    _retry_check("Postgres", check_postgres)
    _retry_check("Redis", check_redis)
    _retry_check("Minio", check_minio)
