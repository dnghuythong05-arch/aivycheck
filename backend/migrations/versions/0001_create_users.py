"""Tạo bảng tài khoản."""

from alembic import op
import sqlalchemy as sa


revision = "0001_create_users"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("username", sa.String(64), nullable=False),
        sa.Column("full_name", sa.String(120), nullable=False),
        sa.Column("email", sa.String(254), nullable=False),
        sa.Column("password_hash", sa.Text(), nullable=False),
        sa.Column("role", sa.String(16), nullable=False),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint(
            "username",
            name="uq_users_username",
        ),
        sa.UniqueConstraint(
            "email",
            name="uq_users_email",
        ),
        sa.CheckConstraint(
            "username ~ '^[a-z0-9_]+$'",
            name="ck_users_username",
        ),
        sa.CheckConstraint(
            "email = lower(btrim(email))",
            name="ck_users_email_normalized",
        ),
        sa.CheckConstraint(
            "role IN ('admin', 'employee')",
            name="ck_users_role",
        ),
    )


def downgrade() -> None:
    op.drop_table("users")