from uuid import uuid4

from fastapi import HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..auth.models import AuthSession
from ..attendance.models import Attendance
from ..security import hash_password
from .models import User
from .schemas import EmployeeCreate, EmployeeUpdate


def list_employees(db: Session) -> list[User]:
    return list(
        db.scalars(
            select(User)
            .where(
                User.role == "employee",
                User.is_active.is_(True),
            )
            .order_by(User.full_name, User.id)
        ).all()
    )


def check_available(
    db: Session,
    username: str,
    email: str,
    exclude_id: str | None = None,
) -> None:
    for column, value, message in (
        (
            User.username,
            username,
            "Tên tài khoản đã được sử dụng.",
        ),
        (
            User.email,
            email,
            "Email đã được sử dụng.",
        ),
    ):
        query = select(User.id).where(column == value)

        if exclude_id is not None:
            query = query.where(User.id != exclude_id)

        if db.scalar(query) is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=message,
            )


def commit_user(db: Session, user: User) -> User:
    try:
        db.commit()

    except IntegrityError as error:
        db.rollback()

        if getattr(error.orig, "sqlstate", None) == "23505":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Tên tài khoản hoặc email đã được sử dụng.",
            ) from None

        raise

    db.refresh(user)
    return user


def create_employee(
    db: Session,
    payload: EmployeeCreate,
) -> User:
    check_available(
        db,
        payload.username,
        payload.email,
    )

    user = User(
        id=f"employee_{uuid4().hex}",
        username=payload.username,
        full_name=payload.full_name,
        email=payload.email,
        role="employee",
        is_active=True,
        password_hash=hash_password(
            payload.password.get_secret_value()
        ),
    )

    db.add(user)
    return commit_user(db, user)


def delete_employee(
    db: Session,
    actor: User,
    user_id: str,
) -> None:
    if actor.role != "admin":
        raise HTTPException(
            403,
            "Chỉ Admin được xóa tài khoản nhân viên.",
        )

    user = db.scalar(
        select(User)
        .where(User.id == user_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )

    if user is None:
        raise HTTPException(
            404,
            "Không tìm thấy tài khoản nhân viên.",
        )

    if user.role != "employee" or user.id == actor.id:
        raise HTTPException(
            403,
            "Không được xóa tài khoản Admin.",
        )

    active = db.scalar(
        select(Attendance.id)
        .where(
            Attendance.user_id == user.id,
            Attendance.check_out.is_(None),
        )
    )

    if active is not None:
        raise HTTPException(
            409,
            "Nhân viên còn ca đang làm. "
            "Hãy CHECK OUT trước khi xóa tài khoản.",
        )

    # Giữ dữ liệu cũ; khóa tài khoản và thu hồi phiên.
    user.is_active = False

    db.execute(
        delete(AuthSession)
        .where(AuthSession.user_id == user.id)
    )

    db.commit()


def update_employee(
    db: Session,
    user_id: str,
    payload: EmployeeUpdate,
) -> User:
    user = db.scalar(
        select(User)
        .where(
            User.id == user_id,
            User.role == "employee",
            User.is_active.is_(True),
        )
        .with_for_update()
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy tài khoản nhân viên.",
        )

    check_available(
        db,
        payload.username,
        payload.email,
        exclude_id=user.id,
    )

    user.username = payload.username
    user.full_name = payload.full_name
    user.email = payload.email

    if payload.password is not None:
        user.password_hash = hash_password(
            payload.password.get_secret_value()
        )

        db.execute(
            delete(AuthSession)
            .where(AuthSession.user_id == user.id)
            .execution_options(autoflush=False)
        )

    return commit_user(db, user)