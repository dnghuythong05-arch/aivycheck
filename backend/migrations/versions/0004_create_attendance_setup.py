"""Lưu địa điểm chấm công và hồ sơ khuôn mặt."""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0004_create_attendance_setup"
down_revision = "0003_create_work_shifts"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "workplaces",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("radius_meters", sa.Float(), nullable=False),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.CheckConstraint(
            "id = 1",
            name="ck_workplaces_singleton",
        ),
        sa.CheckConstraint(
            "radius_meters >= 1 AND radius_meters <= 5000",
            name="ck_workplaces_radius",
        ),
        sa.CheckConstraint(
            "(latitude IS NULL AND longitude IS NULL) OR "
            "(latitude IS NOT NULL AND longitude IS NOT NULL AND "
            "latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)",
            name="ck_workplaces_coordinates",
        ),
    )

    op.create_table(
        "face_profiles",
        sa.Column(
            "user_id",
            sa.String(64),
            primary_key=True,
        ),
        sa.Column(
            "profile",
            postgresql.JSONB(none_as_null=True),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
    )


def downgrade() -> None:
    op.drop_table("face_profiles")
    op.drop_table("workplaces")