"""Tạo bảng ca làm."""

from alembic import op
import sqlalchemy as sa


revision = "0003_create_work_shifts"
down_revision = "0002_create_auth_sessions"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "work_shifts",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("name", sa.String(40), nullable=False),
        sa.Column(
            "starts_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "ends_at",
            sa.DateTime(timezone=True),
            nullable=False,
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
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="RESTRICT",
        ),
        sa.CheckConstraint(
            "ends_at > starts_at",
            name="ck_work_shifts_time",
        ),
    )

    op.create_index(
        "ix_work_shifts_user_start",
        "work_shifts",
        ["user_id", "starts_at"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_work_shifts_user_start",
        table_name="work_shifts",
    )
    op.drop_table("work_shifts")