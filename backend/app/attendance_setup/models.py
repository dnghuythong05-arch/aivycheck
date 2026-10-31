from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class Workplace(Base):
    __tablename__ = "workplaces"
    __table_args__ = (
        CheckConstraint("id = 1", name="ck_workplaces_singleton"),
        CheckConstraint(
            "radius_meters >= 1 AND radius_meters <= 5000",
            name="ck_workplaces_radius",
        ),
        CheckConstraint(
            "(latitude IS NULL AND longitude IS NULL) OR "
            "(latitude IS NOT NULL AND longitude IS NOT NULL AND "
            "latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)",
            name="ck_workplaces_coordinates",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    radius_meters: Mapped[float] = mapped_column(Float, nullable=False)

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )


class FaceProfileRow(Base):
    __tablename__ = "face_profiles"

    user_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )

    # Giữ hàng profile=NULL sau khi xóa để không nhập lại mẫu local cũ.
    profile: Mapped[dict | None] = mapped_column(
        JSONB(none_as_null=True),
        nullable=True,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )