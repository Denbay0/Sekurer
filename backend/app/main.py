import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from starlette.requests import Request

from app.api.v1 import auth, automation, calendar_items, calls, tasks, worker
from app.core.config import settings
from app.core.logging import configure_logging
from app.core.startup import check_required_services

configure_logging()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    check_required_services()
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.include_router(auth.router, prefix=f"{settings.api_v1_prefix}/auth", tags=["auth"])
app.include_router(auth.router, tags=["auth-legacy"])
app.include_router(calls.router, prefix=f"{settings.api_v1_prefix}/calls", tags=["calls"])
app.include_router(tasks.router, prefix=f"{settings.api_v1_prefix}/tasks", tags=["tasks"])
app.include_router(calendar_items.router, prefix=f"{settings.api_v1_prefix}/calendar-items", tags=["calendar-items"])
app.include_router(worker.router, prefix=f"{settings.api_v1_prefix}/worker", tags=["worker"])
app.include_router(worker.router, prefix="/worker", tags=["worker-legacy"])
app.include_router(automation.router, prefix=f"{settings.api_v1_prefix}/automation", tags=["automation"])
app.include_router(automation.router, prefix="/automation", tags=["automation-legacy"])


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled API error on %s %s", request.method, request.url.path)
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}
