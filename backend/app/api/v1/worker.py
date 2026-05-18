from typing import Any

from fastapi import APIRouter
from pydantic import BaseModel

from app.core.startup import check_minio, check_postgres, check_redis
from app.workers.celery_app import celery_app

router = APIRouter()


class WorkerStatusResponse(BaseModel):
    status: str
    postgres: str
    redis: str
    minio: str
    workers: list[str]
    active_tasks: int
    details: dict[str, Any] = {}


def _service_status(check) -> tuple[str, str | None]:
    try:
        check()
        return "ok", None
    except Exception as exc:
        return "error", str(exc)


@router.get("/status", response_model=WorkerStatusResponse)
def worker_status() -> WorkerStatusResponse:
    postgres, postgres_error = _service_status(check_postgres)
    redis, redis_error = _service_status(check_redis)
    minio, minio_error = _service_status(check_minio)

    worker_names: list[str] = []
    active_tasks = 0
    celery_error = None
    try:
        inspector = celery_app.control.inspect(timeout=1.0)
        ping_result = inspector.ping() or {}
        active_result = inspector.active() or {}
        worker_names = sorted(ping_result.keys())
        active_tasks = sum(len(tasks) for tasks in active_result.values())
    except Exception as exc:
        celery_error = str(exc)

    details = {}
    if postgres_error:
        details["postgres_error"] = postgres_error
    if redis_error:
        details["redis_error"] = redis_error
    if minio_error:
        details["minio_error"] = minio_error
    if celery_error:
        details["celery_error"] = celery_error

    is_ok = postgres == redis == minio == "ok" and bool(worker_names) and not celery_error
    return WorkerStatusResponse(
        status="ok" if is_ok else "degraded",
        postgres=postgres,
        redis=redis,
        minio=minio,
        workers=worker_names,
        active_tasks=active_tasks,
        details=details,
    )
