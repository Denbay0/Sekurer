from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.db.models import CalendarItem, CalendarItemStatus, User
from app.schemas.calendar import CalendarItemResponse, CalendarItemUpdateRequest

router = APIRouter()


@router.get("", response_model=list[CalendarItemResponse])
def list_calendar_items(
    status: CalendarItemStatus | None = None,
    from_dt: datetime | None = Query(default=None, alias="from"),
    to: datetime | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[CalendarItemResponse]:
    stmt = select(CalendarItem).where(CalendarItem.user_id == current_user.id)
    if status:
        stmt = stmt.where(CalendarItem.status == status)
    if from_dt:
        stmt = stmt.where(CalendarItem.start_time >= from_dt)
    if to:
        stmt = stmt.where(CalendarItem.start_time <= to)
    items = db.scalars(stmt.order_by(CalendarItem.created_at.desc())).all()
    return [CalendarItemResponse.model_validate(i, from_attributes=True) for i in items]


@router.patch("/{item_id}", response_model=CalendarItemResponse)
def update_calendar_item(item_id: UUID, payload: CalendarItemUpdateRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> CalendarItemResponse:
    item = db.scalar(select(CalendarItem).where(CalendarItem.id == item_id, CalendarItem.user_id == current_user.id))
    if not item:
        raise HTTPException(status_code=404, detail="Calendar item not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return CalendarItemResponse.model_validate(item, from_attributes=True)
