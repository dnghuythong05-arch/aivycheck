from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from ..shifts.service import require_target
from ..users.models import User
from .models import FaceProfileRow, Workplace
from .schemas import FaceProfilePayload, GpsPayload


def read_gps(db: Session) -> GpsPayload:
    row = db.get(Workplace, 1)

    if row is None:
        return GpsPayload()

    return GpsPayload(
        latitude=row.latitude,
        longitude=row.longitude,
        radius_meters=row.radius_meters,
    )


def save_gps(
    db: Session,
    payload: GpsPayload,
    *,
    importing: bool = False,
) -> GpsPayload:
    values = payload.model_dump()

    statement = insert(Workplace).values(
        id=1,
        **values,
    )

    if importing:
        statement = statement.on_conflict_do_nothing(
            index_elements=["id"],
        )
    else:
        statement = statement.on_conflict_do_update(
            index_elements=["id"],
            set_={
                **values,
                "updated_at": func.now(),
            },
        )

    db.execute(statement)
    db.commit()
    db.expire_all()

    return read_gps(db)


def clear_gps(db: Session) -> GpsPayload:
    statement = (
        insert(Workplace)
        .values(
            id=1,
            latitude=None,
            longitude=None,
            radius_meters=200.0,
        )
        .on_conflict_do_update(
            index_elements=["id"],
            set_={
                "latitude": None,
                "longitude": None,
                "updated_at": func.now(),
            },
        )
    )

    db.execute(statement)
    db.commit()
    db.expire_all()

    return read_gps(db)


def read_face(
    db: Session,
    actor: User,
    user_id: str,
) -> FaceProfilePayload | None:
    require_target(db, actor, user_id)

    row = db.get(FaceProfileRow, user_id)

    if row is None or row.profile is None:
        return None

    return FaceProfilePayload.model_validate(row.profile)


def face_ids(db: Session, actor: User) -> list[str]:
    query = (
        select(FaceProfileRow.user_id)
        .join(User, User.id == FaceProfileRow.user_id)
        .where(
            FaceProfileRow.profile.is_not(None),
            User.is_active.is_(True),
            (User.role == "employee") | (User.id == actor.id),
        )
        .order_by(FaceProfileRow.user_id)
    )

    return list(db.scalars(query).all())


def save_face(
    db: Session,
    actor: User,
    user_id: str,
    profile: FaceProfilePayload | None,
    *,
    importing: bool = False,
) -> FaceProfilePayload | None:
    require_target(db, actor, user_id)

    value = (
        profile.model_dump(mode="json")
        if profile is not None
        else None
    )

    statement = insert(FaceProfileRow).values(
        user_id=user_id,
        profile=value,
    )

    if importing:
        statement = statement.on_conflict_do_nothing(
            index_elements=["user_id"],
        )
    else:
        statement = statement.on_conflict_do_update(
            index_elements=["user_id"],
            set_={
                "profile": value,
                "updated_at": func.now(),
            },
        )

    db.execute(statement)
    db.commit()
    db.expire_all()

    return read_face(db, actor, user_id)