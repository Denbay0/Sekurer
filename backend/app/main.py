from fastapi import FastAPI

from app.api.v1 import auth, calendar_items, calls, tasks
from app.core.config import settings

app = FastAPI(title=settings.app_name)
app.include_router(auth.router, prefix=f"{settings.api_v1_prefix}/auth", tags=["auth"])
app.include_router(calls.router, prefix=f"{settings.api_v1_prefix}/calls", tags=["calls"])
app.include_router(tasks.router, prefix=f"{settings.api_v1_prefix}/tasks", tags=["tasks"])
app.include_router(calendar_items.router, prefix=f"{settings.api_v1_prefix}/calendar-items", tags=["calendar-items"])


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}
