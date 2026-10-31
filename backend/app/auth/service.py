import hashlib
import secrets
from datetime import UTC, datetime, timedelta

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from ..security import hash_password, verify_password
from ..users.models import User
from .models import AuthSession


DUMMY_PASSWORD_HASH = hash_password(secrets.token_urlsafe(32))


def token_digest(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def authenticate_user(
    db: Session,
    username: str,
    password: str,
) -> User | None:
    user = db.scalar(
        select(User).where(User.username == username)
    )

    stored_hash = (
        user.password_hash
        if user is not None
        else DUMMY_PASSWORD_HASH
    )

    matched = verify_password(password, stored_hash)

    if user is None or not matched or not user.is_active:
        return None

    return user


def create_session(
    db: Session,
    user: User,
    hours: int,
) -> tuple[str, datetime]:
    now = datetime.now(UTC)
    expires_at = now + timedelta(hours=hours)
    token = secrets.token_urlsafe(32)

    db.execute(
        delete(AuthSession).where(AuthSession.expires_at <= now)
    )

    db.add(
        AuthSession(
            token_hash=token_digest(token),
            user_id=user.id,
            expires_at=expires_at,
        )
    )

    db.commit()

    return token, expires_at


def find_session(
    db: Session,
    token: str,
) -> AuthSession | None:
    if len(token) != 43:
        return None

    session = db.get(AuthSession, token_digest(token))

    if (
        session is None
        or session.expires_at <= datetime.now(UTC)
        or not session.user.is_active
    ):
        return None

    return session


def revoke_session(
    db: Session,
    session: AuthSession,
) -> None:
    db.delete(session)
    db.commit()