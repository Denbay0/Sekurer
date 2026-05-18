from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import create_access_token, get_password_hash, verify_password
from app.db.models import User


class AuthService:
    def register(self, db: Session, email: str, password: str, name: str) -> str:
        existing = db.scalar(select(User).where(User.email == email))
        if existing:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
        display_name = name.strip() or email.split("@", 1)[0]
        user = User(email=email, password_hash=get_password_hash(password), name=display_name)
        db.add(user)
        db.commit()
        db.refresh(user)
        return create_access_token(str(user.id))

    def login(self, db: Session, email: str, password: str) -> str:
        user = db.scalar(select(User).where(User.email == email))
        if not user or not verify_password(password, user.password_hash):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
        return create_access_token(str(user.id))
