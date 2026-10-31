"""Lưu CHECK IN/OUT vào PostgreSQL."""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0005_create_attendance"
down_revision = "0004_create_attendance_setup"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "attendance_records",
        sa.Column(
            "id",
            sa.String(64),
            primary_key=True,
        ),
        sa.Column(
            "user_id",
            sa.String(64),
            sa.ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "shift_id",
            sa.String(64),
            sa.ForeignKey("work_shifts.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "shift_snapshot",
            postgresql.JSONB(),
            nullable=False,
        ),
        sa.Column(
            "check_in",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "check_out",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
        sa.Column(
            "check_in_gps",
            postgresql.JSONB(),
            nullable=False,
        ),
        sa.Column(
            "check_out_gps",
            postgresql.JSONB(),
            nullable=True,
        ),
        sa.Column(
            "check_in_request",
            sa.String(80),
            nullable=False,
            unique=True,
        ),
        sa.Column(
            "check_out_request",
            sa.String(80),
            nullable=True,
            unique=True,
        ),
        sa.Column(
            "is_deleted",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.UniqueConstraint(
            "shift_id",
            name="uq_attendance_shift",
        ),
        sa.CheckConstraint(
            "check_out IS NULL OR check_out >= check_in",
            name="ck_attendance_times",
        ),
        sa.CheckConstraint(
            "NOT is_deleted OR check_out IS NOT NULL",
            name="ck_attendance_delete_completed",
        ),
    )

    op.create_index(
        "ix_attendance_user_time",
        "attendance_records",
        ["user_id", "check_in"],
    )

    op.create_index(
        "uq_attendance_active_user",
        "attendance_records",
        ["user_id"],
        unique=True,
        postgresql_where=sa.text("check_out IS NULL"),
    )


def downgrade() -> None:
    op.drop_index(
        "uq_attendance_active_user",
        table_name="attendance_records",
    )

    op.drop_index(
        "ix_attendance_user_time",
        table_name="attendance_records",
    )

    op.drop_table("attendance_records")