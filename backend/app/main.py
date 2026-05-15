from fastapi import FastAPI

from app.api.v1 import auth
from app.core.config import settings

app = FastAPI(title=settings.app_name)
app.include_router(auth.router, prefix=f"{settings.api_v1_prefix}/auth", tags=["auth"])


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}
