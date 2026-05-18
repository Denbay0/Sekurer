import logging
from typing import Any

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()
logger = logging.getLogger("codex.automation")


class AutomationLogRequest(BaseModel):
    event: str = "final_smoke"
    payload: dict[str, Any]


@router.post("/log")
def log_automation_result(payload: AutomationLogRequest) -> dict[str, str]:
    logger.info("%s %s", payload.event, payload.payload)
    return {"status": "logged"}
