import logging
import traceback
from datetime import UTC, date, datetime
from uuid import UUID

from sqlalchemy import delete

from app.db.models import Agreement, AgreementOwner, CalendarItem, Call, CallStatus, Task, TaskPriority, UnclearPoint
from app.db.session import SessionLocal
from app.services.ai_service import AIService
from app.services.storage_service import StorageService
from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


def parse_date_or_none(value: str | None) -> date | None:
    if not value:
        return None
    try:
        return date.fromisoformat(value)
    except (TypeError, ValueError):
        return None


def parse_datetime_or_none(value: str | None) -> datetime | None:
    if not value:
        return None
    normalized = value.replace("Z", "+00:00") if isinstance(value, str) else value
    try:
        return datetime.fromisoformat(normalized)
    except (TypeError, ValueError):
        return None


def safe_agreement_owner(value: str | None) -> AgreementOwner:
    if value in {AgreementOwner.me.value, AgreementOwner.other.value, AgreementOwner.unknown.value}:
        return AgreementOwner(value)
    return AgreementOwner.unknown


def safe_task_priority(value: str | None) -> TaskPriority:
    if value in {TaskPriority.low.value, TaskPriority.medium.value, TaskPriority.high.value}:
        return TaskPriority(value)
    return TaskPriority.medium


@celery_app.task(name="process_call")
def process_call(call_id: str) -> None:
    db = SessionLocal()
    storage = StorageService()
    ai_service = AIService()
    try:
        call = db.get(Call, UUID(call_id))
        if not call:
            return

        call.status = CallStatus.transcribing
        db.commit()

        if not call.audio_file_url:
            raise ValueError("Call audio_file_url is empty")

        audio_bytes = storage.get_object_bytes(call.audio_file_url)
        transcript = ai_service.transcribe_audio(audio_bytes, call.audio_original_filename or "audio", call.audio_content_type)
        call.transcript = transcript
        call.status = CallStatus.analyzing
        db.commit()

        analysis = ai_service.analyze_transcript(transcript, call.created_at)
        call.title = analysis.get("call_title") or call.title
        call.summary = analysis.get("summary")

        db.execute(delete(Agreement).where(Agreement.call_id == call.id))
        db.execute(delete(Task).where(Task.call_id == call.id))
        db.execute(delete(CalendarItem).where(CalendarItem.call_id == call.id))
        db.execute(delete(UnclearPoint).where(UnclearPoint.call_id == call.id))

        for a in analysis.get("agreements", []):
            db.add(
                Agreement(
                    call_id=call.id,
                    text=a.get("text", ""),
                    owner=safe_agreement_owner(a.get("owner", "unknown")),
                    deadline=parse_date_or_none(a.get("deadline")),
                    confidence=a.get("confidence"),
                    source_quote=a.get("source_quote"),
                )
            )
        for t in analysis.get("tasks", []):
            db.add(
                Task(
                    call_id=call.id,
                    user_id=call.user_id,
                    title=t.get("title", "Без названия"),
                    description=t.get("description"),
                    due_date=parse_date_or_none(t.get("due_date")),
                    priority=safe_task_priority(t.get("priority", "medium")),
                    requires_confirmation=t.get("requires_confirmation", True),
                    source_quote=t.get("source_quote"),
                )
            )
        for e in analysis.get("calendar_events", []):
            db.add(
                CalendarItem(
                    call_id=call.id,
                    user_id=call.user_id,
                    title=e.get("title", "Событие"),
                    description=e.get("description"),
                    start_time=parse_datetime_or_none(e.get("start_time")),
                    end_time=parse_datetime_or_none(e.get("end_time")),
                    requires_confirmation=e.get("requires_confirmation", True),
                )
            )
        for p in analysis.get("unclear_points", []):
            db.add(UnclearPoint(call_id=call.id, text=p))

        call.status = CallStatus.ready
        call.processed_at = datetime.now(UTC)
        call.error_message = None
        db.commit()
    except Exception as exc:
        logger.exception("process_call failed for call_id=%s\n%s", call_id, traceback.format_exc())
        db.rollback()
        call = db.get(Call, UUID(call_id))
        if call:
            call.status = CallStatus.failed
            call.error_message = str(exc)[:1000]
            db.commit()
    finally:
        db.close()
