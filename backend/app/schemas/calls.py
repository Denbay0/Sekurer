from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel

from app.db.models import AgreementOwner, CalendarItemStatus, CallStatus, TaskPriority, TaskStatus


class AgreementResponse(BaseModel):
    id: UUID
    call_id: UUID
    text: str
    owner: AgreementOwner
    deadline: date | None
    confidence: float | None
    source_quote: str | None


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


class UnclearPointResponse(BaseModel):
    id: UUID
    call_id: UUID
    text: str


class CallListItem(BaseModel):
    id: UUID
    title: str | None
    contact_name: str | None
    phone_number: str | None
    status: CallStatus
    created_at: datetime
    processed_at: datetime | None


class CallUploadResponse(BaseModel):
    id: UUID
    status: CallStatus


class CallDetail(CallListItem):
    audio_original_filename: str | None
    audio_content_type: str | None
    audio_size_bytes: int | None
    transcript: str | None
    summary: str | None
    error_message: str | None
    agreements: list[AgreementResponse]
    tasks: list[TaskResponse]
    calendar_items: list[CalendarItemResponse]
    unclear_points: list[UnclearPointResponse]
