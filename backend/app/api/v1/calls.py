from io import BytesIO
from pathlib import Path
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import get_current_user, get_db
from app.db.models import Call, CallStatus, User
from app.schemas.calls import CallDetail, CallListItem, CallUploadResponse
from app.services.storage_service import StorageService
from app.workers.tasks import process_call

router = APIRouter()
storage = StorageService()
ALLOWED_EXTENSIONS = {".mp3", ".m4a", ".wav", ".aac", ".ogg", ".webm"}
MAX_AUDIO_SIZE_BYTES = 25 * 1024 * 1024


class CallTranscriptResponse(BaseModel):
    call_id: UUID
    transcript: str | None


@router.post("/upload", response_model=CallUploadResponse)
async def upload_call(
    file: UploadFile = File(...),
    title: str | None = Form(default=None),
    contact_name: str | None = Form(default=None),
    phone_number: str | None = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> CallUploadResponse:
    ext = Path(file.filename or "").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Unsupported audio file extension")

    file_bytes = await file.read()
    if len(file_bytes) > MAX_AUDIO_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="File too large")

    call = Call(user_id=current_user.id, title=title, contact_name=contact_name, phone_number=phone_number, status=CallStatus.uploaded)
    db.add(call)
    db.flush()

    storage.ensure_bucket_exists()
    object_key = storage.generate_object_key(str(current_user.id), str(call.id), file.filename or "audio")
    storage.upload_fileobj(BytesIO(file_bytes), object_key=object_key, content_type=file.content_type)

    call.audio_file_url = object_key
    call.audio_original_filename = file.filename
    call.audio_content_type = file.content_type
    call.audio_size_bytes = len(file_bytes)
    db.commit()

    process_call.delay(str(call.id))
    return CallUploadResponse(id=call.id, status=call.status)


@router.post("/{call_id}/retry", response_model=CallUploadResponse)
def retry_call_processing(call_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> CallUploadResponse:
    call = db.scalar(select(Call).where(Call.id == call_id, Call.user_id == current_user.id))
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")
    if call.status == CallStatus.ready:
        raise HTTPException(status_code=400, detail="Call is already processed")
    if not call.audio_file_url:
        raise HTTPException(status_code=400, detail="Call has no audio file")

    call.error_message = None
    call.status = CallStatus.uploaded
    db.commit()

    process_call.delay(str(call.id))
    return CallUploadResponse(id=call.id, status=call.status)


@router.get("", response_model=list[CallListItem])
def list_calls(
    limit: int = Query(default=50, le=100),
    offset: int = 0,
    status_filter: CallStatus | None = Query(default=None, alias="status"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[CallListItem]:
    stmt = select(Call).where(Call.user_id == current_user.id)
    if status_filter:
        stmt = stmt.where(Call.status == status_filter)
    calls = db.scalars(stmt.order_by(Call.created_at.desc()).limit(limit).offset(offset)).all()
    return [CallListItem.model_validate(c, from_attributes=True) for c in calls]


@router.get("/{call_id}", response_model=CallDetail)
def get_call(call_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> CallDetail:
    stmt = (
        select(Call)
        .where(Call.id == call_id, Call.user_id == current_user.id)
        .options(selectinload(Call.agreements), selectinload(Call.tasks), selectinload(Call.calendar_items), selectinload(Call.unclear_points))
    )
    call = db.scalar(stmt)
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")
    return CallDetail.model_validate(call, from_attributes=True)


@router.get("/{call_id}/transcript", response_model=CallTranscriptResponse)
def get_call_transcript(call_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> CallTranscriptResponse:
    call = db.scalar(select(Call).where(Call.id == call_id, Call.user_id == current_user.id))
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")
    return CallTranscriptResponse(call_id=call.id, transcript=call.transcript)


@router.delete("/{call_id}")
def delete_call(call_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> dict[str, str]:
    call = db.scalar(select(Call).where(Call.id == call_id, Call.user_id == current_user.id))
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")
    if call.audio_file_url:
        try:
            storage.delete_object(call.audio_file_url)
        except Exception:
            pass
    db.delete(call)
    db.commit()
    return {"status": "deleted"}
