import logging

from fastapi import APIRouter, Depends, HTTPException
from redis.exceptions import RedisError
from sqlalchemy.exc import OperationalError, SQLAlchemyError
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.db.models import User
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserResponse
from app.services.auth_service import AuthService

router = APIRouter()
service = AuthService()
logger = logging.getLogger(__name__)


def _rollback(db: Session) -> None:
    try:
        db.rollback()
    except Exception:
        logger.exception("Failed to rollback auth DB session")


@router.post("/register", response_model=TokenResponse)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> TokenResponse:
    try:
        token = service.register(db, payload.email, payload.password, payload.name)
        return TokenResponse(access_token=token)
    except OperationalError as exc:
        _rollback(db)
        logger.exception("Registration failed because database connection is unavailable for email=%s", payload.email)
        raise HTTPException(status_code=500, detail="Database connection failed") from exc
    except RedisError as exc:
        _rollback(db)
        logger.exception("Registration failed because Redis is unavailable for email=%s", payload.email)
        raise HTTPException(status_code=500, detail="Redis unavailable") from exc
    except SQLAlchemyError as exc:
        _rollback(db)
        logger.exception("Registration failed because of a database error for email=%s", payload.email)
        raise HTTPException(status_code=500, detail="Database error") from exc
    except HTTPException:
        raise
    except Exception as exc:
        _rollback(db)
        logger.exception("Unexpected registration error for email=%s", payload.email)
        raise HTTPException(status_code=500, detail="Registration failed") from exc


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    try:
        token = service.login(db, payload.email, payload.password)
        return TokenResponse(access_token=token)
    except OperationalError as exc:
        _rollback(db)
        logger.exception("Login failed because database connection is unavailable for email=%s", payload.email)
        raise HTTPException(status_code=500, detail="Database connection failed") from exc
    except SQLAlchemyError as exc:
        _rollback(db)
        logger.exception("Login failed because of a database error for email=%s", payload.email)
        raise HTTPException(status_code=500, detail="Database error") from exc
    except HTTPException:
        raise
    except Exception as exc:
        _rollback(db)
        logger.exception("Unexpected login error for email=%s", payload.email)
        raise HTTPException(status_code=500, detail="Login failed") from exc


@router.get("/me", response_model=UserResponse)
def me(current_user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse(id=str(current_user.id), email=current_user.email, name=current_user.name)
