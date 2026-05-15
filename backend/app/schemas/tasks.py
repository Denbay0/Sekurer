from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel

from app.db.models import TaskPriority, TaskStatus


class TaskResponse(BaseModel):
    id: UUID
    call_id: UUID
    user_id: UUID
    title: str
    description: str | None
    due_date: date | None
    priority: TaskPriority
    status: TaskStatus
    requires_confirmation: bool
    source_quote: str | None
    created_at: datetime
    updated_at: datetime


class TaskUpdateRequest(BaseModel):
    title: str | None = None
    description: str | None = None
    due_date: date | None = None
    priority: TaskPriority | None = None
    status: TaskStatus | None = None
    requires_confirmation: bool | None = None
