from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from ..database import get_db
from ..users.models import User
from .models import AuthSession
from .service import find_session


bearer = HTTPBearer(
    auto_error=False,
    scheme_name="BearerAuth",
)

Database = Annotated[Session, Depends(get_db)]


def get_auth_session(
    db: Database,
    credentials: Annotated[
        HTTPAuthorizationCredentials | None,
        Depends(bearer),
    ],
) -> AuthSession:
    session = None

    if credentials is not None and credentials.scheme.lower() == "bearer":
        session = find_session(db, credentials.credentials)

    if session is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Phiên đăng nhập không hợp lệ hoặc đã hết hạn.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return session


CurrentSession = Annotated[
    AuthSession,
    Depends(get_auth_session),
]


def get_current_user(session: CurrentSession) -> User:
    return session.user


CurrentUser = Annotated[User, Depends(get_current_user)]


def require_admin(user: CurrentUser) -> User:
    if user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Chỉ Admin được thực hiện thao tác này.",
        )

    return user