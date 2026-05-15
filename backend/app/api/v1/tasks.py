from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.db.models import Task, TaskStatus, User
from app.schemas.tasks import TaskResponse, TaskUpdateRequest

router = APIRouter()


@router.get("", response_model=list[TaskResponse])
def list_tasks(
    status: TaskStatus | None = None,
    due_from: date | None = None,
    due_to: date | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[TaskResponse]:
    stmt = select(Task).where(Task.user_id == current_user.id)
    if status:
        stmt = stmt.where(Task.status == status)
    if due_from:
        stmt = stmt.where(Task.due_date >= due_from)
    if due_to:
        stmt = stmt.where(Task.due_date <= due_to)
    items = db.scalars(stmt.order_by(Task.created_at.desc())).all()
    return [TaskResponse.model_validate(i, from_attributes=True) for i in items]


@router.patch("/{task_id}", response_model=TaskResponse)
def update_task(task_id: UUID, payload: TaskUpdateRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)) -> TaskResponse:
    task = db.scalar(select(Task).where(Task.id == task_id, Task.user_id == current_user.id))
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, field, value)
    db.commit()
    db.refresh(task)
    return TaskResponse.model_validate(task, from_attributes=True)
