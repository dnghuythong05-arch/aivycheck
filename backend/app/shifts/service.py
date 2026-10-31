import hashlib
import json
from datetime import UTC
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import or_, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from ..users.models import User
from ..attendance.models import Attendance
from .models import WorkShift
from .schemas import LegacyShift, ShiftCreate, ShiftUpdate


def require_target(db: Session, actor: User, user_id: str) -> User:
    if actor.role != "admin" and user_id != actor.id:
        raise HTTPException(
            status_code=403,
            detail="Bạn chỉ được xem lịch làm của mình.",
        )

    user = db.get(User, user_id)

    if (
        user is None
        or not user.is_active
        or (user.role == "admin" and user.id != actor.id)
    ):
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy tài khoản được giao ca.",
        )

    return user


def list_shifts(
    db: Session,
    actor: User,
    user_id: str | None,
) -> list[WorkShift]:
    query = (
        select(WorkShift)
        .join(User, User.id == WorkShift.user_id)
        .where(
            WorkShift.is_deleted.is_(False),
            User.is_active.is_(True),
        )
    )

    if actor.role == "admin" and user_id is None:
        query = query.where(
            or_(User.role == "employee", User.id == actor.id)
        )
    else:
        target = require_target(
            db,
            actor,
            user_id if user_id is not None else actor.id,
        )
        query = query.where(WorkShift.user_id == target.id)

    return list(
        db.scalars(
            query.order_by(WorkShift.starts_at, WorkShift.id)
        ).all()
    )


def create_shift(
    db: Session,
    actor: User,
    payload: ShiftCreate,
) -> WorkShift:
    require_target(db, actor, payload.user_id)

    shift = WorkShift(
        id=f"shift_db_{uuid4().hex}",
        user_id=payload.user_id,
        name=payload.name,
        starts_at=payload.start.astimezone(UTC),
        ends_at=payload.end.astimezone(UTC),
        is_deleted=False,
    )

    db.add(shift)
    db.commit()
    db.refresh(shift)

    return shift


def find_shift(
    db: Session,
    actor: User,
    shift_id: str,
) -> WorkShift:
    shift = db.scalar(
        select(WorkShift)
        .where(WorkShift.id == shift_id)
        .with_for_update()
    )

    if shift is None:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy ca làm.",
        )

    require_target(db, actor, shift.user_id)

    return shift


def update_shift(
    db: Session,
    actor: User,
    shift_id: str,
    payload: ShiftUpdate,
) -> WorkShift:
    shift = find_shift(db, actor, shift_id)

    if shift.is_deleted:
        raise HTTPException(
            status_code=409,
            detail="Ca này đã bị xóa. Hãy tải lại lịch làm.",
        )

    shift.name = payload.name
    shift.starts_at = payload.start.astimezone(UTC)
    shift.ends_at = payload.end.astimezone(UTC)

    db.commit()
    db.refresh(shift)

    return shift


def delete_shift(
    db: Session,
    actor: User,
    shift_id: str,
) -> None:
    shift = find_shift(db, actor, shift_id)

    active = db.scalar(
        select(Attendance.id)
        .where(
            Attendance.shift_id == shift.id,
            Attendance.check_out.is_(None),
        )
    )

    if active is not None:
        raise HTTPException(
            409,
            "Hãy CHECK OUT ca đang làm trước khi xóa.",
        )

    if not shift.is_deleted:
        shift.is_deleted = True
        db.commit()


def legacy_key(item: LegacyShift) -> str:
    text = json.dumps(
        [
            item.user_id,
            item.legacy_id,
            item.name,
            item.start.astimezone(UTC).isoformat(),
            item.end.astimezone(UTC).isoformat(),
        ],
        ensure_ascii=False,
        separators=(",", ":"),
    )

    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()[:32]

    return "shift_import_" + digest


def import_shifts(
    db: Session,
    actor: User,
    items: list[LegacyShift],
) -> list[tuple[str, WorkShift]]:
    for user_id in {item.user_id for item in items}:
        require_target(db, actor, user_id)

    keys = [legacy_key(item) for item in items]

    values = [
        {
            "id": key,
            "user_id": item.user_id,
            "name": item.name,
            "starts_at": item.start.astimezone(UTC),
            "ends_at": item.end.astimezone(UTC),
            "is_deleted": item.is_deleted,
        }
        for item, key in zip(items, keys)
    ]

    db.execute(
        insert(WorkShift)
        .values(values)
        .on_conflict_do_nothing(index_elements=["id"])
    )
    db.commit()

    saved = {
        row.id: row
        for row in db.scalars(
            select(WorkShift).where(WorkShift.id.in_(keys))
        ).all()
    }

    return [
        (item.legacy_id, saved[key])
        for item, key in zip(items, keys)
    ]