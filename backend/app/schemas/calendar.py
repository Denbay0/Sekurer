from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.db.models import CalendarItemStatus


class CalendarItemResponse(BaseModel):
    id: UUID
    call_id: UUID
    user_id: UUID
    title: str
    description: str | None
    start_time: datetime | None
    end_time: datetime | None
    status: CalendarItemStatus
    requires_confirmation: bool
    created_at: datetime
    updated_at: datetime


class CalendarItemUpdateRequest(BaseModel):
    title: str | None = None
    description: str | None = None
    start_time: datetime | None = None
    end_time: datetime | None = None
    status: CalendarItemStatus | None = None
    requires_confirmation: bool | None = None
