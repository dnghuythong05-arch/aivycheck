from datetime import UTC, datetime, timedelta, timezone
from math import asin, cos, radians, sin, sqrt
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..attendance_setup.models import FaceProfileRow, Workplace
from ..shifts.models import WorkShift
from ..shifts.service import require_target
from ..users.models import User
from .models import Attendance
from .schemas import AttendanceAction, AttendancePublic


VIETNAM = timezone(timedelta(hours=7))


def public(row: Attendance) -> AttendancePublic:
    return AttendancePublic(
        id=row.id,
        userId=row.user_id,
        shiftSnapshot=row.shift_snapshot,
        checkIn=row.check_in,
        checkOut=row.check_out,
    )


def list_records(
    db: Session,
    actor: User,
    user_id: str | None,
):
    target = require_target(db, actor, user_id or actor.id)

    return list(
        db.scalars(
            select(Attendance)
            .where(
                Attendance.user_id == target.id,
                Attendance.is_deleted.is_(False),
            )
            .order_by(
                Attendance.check_in.desc(),
                Attendance.id,
            )
        ).all()
    )


def checked_gps(
    db: Session,
    payload: AttendanceAction,
    now: datetime,
) -> dict:
    place = db.scalar(
        select(Workplace)
        .where(Workplace.id == 1)
        .with_for_update()
    )

    if (
        place is None
        or place.latitude is None
        or place.longitude is None
    ):
        raise HTTPException(
            409,
            "Admin cần thiết lập địa điểm chấm công trước.",
        )

    gps = payload.gps

    age = (
        now - gps.captured_at.astimezone(UTC)
    ).total_seconds()

    if age < -30 or age > 90:
        raise HTTPException(
            409,
            "Vị trí đã cũ hoặc giờ thiết bị chưa đúng. "
            "Hãy cập nhật lại.",
        )

    lat1 = radians(place.latitude)
    lat2 = radians(gps.latitude)

    dlat = lat2 - lat1
    dlon = radians(gps.longitude - place.longitude)

    value = (
        sin(dlat / 2) ** 2
        + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    )

    distance = (
        6378137
        * 2
        * asin(sqrt(min(1.0, max(0.0, value))))
    )

    if distance + gps.accuracy > place.radius_meters:
        raise HTTPException(
            409,
            "Vị trí chưa đạt: khoảng cách cộng sai số "
            "phải nằm trong phạm vi. "
            "Hãy cập nhật vị trí rồi thử lại.",
        )

    return {
        **gps.model_dump(mode="json", by_alias=True),
        "distanceMeters": distance,
        "radiusMeters": place.radius_meters,
        "workplaceLatitude": place.latitude,
        "workplaceLongitude": place.longitude,
    }


def record_action(
    db: Session,
    actor: User,
    payload: AttendanceAction,
    *,
    checking_out: bool,
) -> Attendance:
    # Khóa theo tài khoản để hai tab không mở hai ca đồng thời.
    owner = db.scalar(
        select(User)
        .where(User.id == actor.id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )

    if owner is None or not owner.is_active:
        raise HTTPException(401, "Hãy đăng nhập lại.")

    shift = db.scalar(
        select(WorkShift)
        .where(WorkShift.id == payload.shift_id)
        .with_for_update()
    )

    if shift is None or shift.user_id != owner.id:
        raise HTTPException(
            404,
            "Không tìm thấy ca được giao cho bạn.",
        )

    row = db.scalar(
        select(Attendance)
        .where(Attendance.shift_id == shift.id)
        .with_for_update()
    )

    # Gửi lại cùng requestId thì trả đúng lượt đã lưu.
    if row is not None and row.user_id == owner.id:
        saved_request = (
            row.check_out_request
            if checking_out
            else row.check_in_request
        )

        if (
            saved_request == payload.request_id
            and not row.is_deleted
        ):
            return row

    if checking_out:
        if row is None:
            raise HTTPException(
                409,
                "Bạn chưa CHECK IN ca này.",
            )

        if row.is_deleted or row.check_out is not None:
            raise HTTPException(
                409,
                "Ca này đã hoàn thành hoặc lịch sử đã bị xóa.",
            )
    else:
        if shift.is_deleted:
            raise HTTPException(
                409,
                "Ca đã bị xóa. Hãy tải lại lịch làm.",
            )

        if row is not None:
            raise HTTPException(
                409,
                "Ca này đã có lượt chấm công, "
                "kể cả lượt đã xóa khỏi lịch sử.",
            )

        active = db.scalar(
            select(Attendance.id)
            .where(
                Attendance.user_id == owner.id,
                Attendance.check_out.is_(None),
            )
        )

        if active is not None:
            raise HTTPException(
                409,
                "Bạn còn một ca chưa CHECK OUT. "
                "Hãy tải lại lịch sử.",
            )

    now = datetime.now(UTC)

    if not checking_out:
        day = now.astimezone(VIETNAM).date()
        start = shift.starts_at.astimezone(VIETNAM).date()
        end = shift.ends_at.astimezone(VIETNAM).date()

        if day != start and not (
            start != end and day == end
        ):
            raise HTTPException(
                409,
                "Hãy chọn ca có ngày làm phù hợp với hôm nay.",
            )

    face = db.scalar(
        select(FaceProfileRow)
        .where(FaceProfileRow.user_id == owner.id)
        .with_for_update()
    )

    if face is None or face.profile is None:
        raise HTTPException(
            409,
            "Tài khoản chưa có mẫu khuôn mặt. "
            "Hãy nhờ Admin đăng ký.",
        )

    if face.profile.get("preprocessing") != "equalized-v1":
        raise HTTPException(
            409,
            "Hãy nhờ Admin cập nhật mẫu khuôn mặt.",
        )

    gps = checked_gps(db, payload, now)

    if checking_out:
        if now < row.check_in:
            raise HTTPException(
                409,
                "Giờ máy chủ đang trước giờ CHECK IN. "
                "Hãy kiểm tra lại.",
            )

        row.check_out = now
        row.check_out_gps = gps
        row.check_out_request = payload.request_id
    else:
        row = Attendance(
            id="attendance_" + uuid4().hex,
            user_id=owner.id,
            shift_id=shift.id,
            shift_snapshot={
                "id": shift.id,
                "name": shift.name,
                "start": shift.starts_at.astimezone(UTC).isoformat(),
                "end": shift.ends_at.astimezone(UTC).isoformat(),
            },
            check_in=now,
            check_in_gps=gps,
            check_in_request=payload.request_id,
            is_deleted=False,
        )

        db.add(row)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()

        raise HTTPException(
            409,
            "Lượt chấm công đã thay đổi. "
            "Hãy tải lại lịch sử.",
        ) from None

    db.refresh(row)

    return row


def delete_record(
    db: Session,
    actor: User,
    shift_id: str,
) -> None:
    owner_id = db.scalar(
        select(Attendance.user_id)
        .where(Attendance.shift_id == shift_id)
    )

    if owner_id is None:
        raise HTTPException(
            404,
            "Không tìm thấy lượt chấm công.",
        )

    require_target(db, actor, owner_id)

    db.scalar(
        select(User)
        .where(User.id == owner_id)
        .with_for_update()
    )

    row = db.scalar(
        select(Attendance)
        .where(Attendance.shift_id == shift_id)
        .with_for_update()
    )

    if row.check_out is None:
        raise HTTPException(
            409,
            "Hãy CHECK OUT trước khi xóa lịch sử.",
        )

    row.is_deleted = True
    db.commit()