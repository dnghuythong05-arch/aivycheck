from datetime import datetime

from sqlalchemy import (
    Boolean, CheckConstraint, DateTime, ForeignKey,
    Index, String, UniqueConstraint, false, func, text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class Attendance(Base):
    __tablename__ = "attendance_records"
    __table_args__ = (
        UniqueConstraint("shift_id", name="uq_attendance_shift"),
        CheckConstraint(
            "check_out IS NULL OR check_out >= check_in",
            name="ck_attendance_times",
        ),
        CheckConstraint(
            "NOT is_deleted OR check_out IS NOT NULL",
            name="ck_attendance_delete_completed",
        ),
        Index("ix_attendance_user_time", "user_id", "check_in"),
        Index(
            "uq_attendance_active_user", "user_id", unique=True,
            postgresql_where=text("check_out IS NULL"),
        ),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)

    user_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )

    shift_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("work_shifts.id", ondelete="RESTRICT"),
        nullable=False,
    )

    shift_snapshot: Mapped[dict] = mapped_column(JSONB, nullable=False)

    check_in: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    check_out: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
    )

    check_in_gps: Mapped[dict] = mapped_column(JSONB, nullable=False)
    check_out_gps: Mapped[dict | None] = mapped_column(JSONB)

    check_in_request: Mapped[str] = mapped_column(
        String(80),
        unique=True,
    )

    check_out_request: Mapped[str | None] = mapped_column(
        String(80),
        unique=True,
    )

    is_deleted: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        server_default=false(),
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )