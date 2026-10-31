"""Tạo tài khoản lần đầu trên cloud; giữ nguyên tài khoản đã tồn tại."""

from collections.abc import Mapping

from sqlalchemy import select
from sqlalchemy.orm import Session

from .security import hash_password
from .seed import INITIAL_USERS
from .users.models import User


PASSWORD_KEYS = {
    "admin_aivee": "AIVY_ADMIN_PASSWORD",
    "employee_huythong": "AIVY_EMPLOYEE_PASSWORD",
}


def bootstrap_initial_users(
    session: Session,
    passwords: Mapping[str, str],
) -> list[str]:
    existing = set(session.scalars(select(User.id)).all())
    pending = [data for data in INITIAL_USERS if data["id"] not in existing]

    # Kiểm tra đủ mật khẩu trước khi ghi bất kỳ tài khoản nào.
    for data in pending:
        key = PASSWORD_KEYS[data["id"]]
        if not 8 <= len(passwords.get(key, "")) <= 128:
            raise ValueError(f"Cần đặt {key} từ 8 đến 128 ký tự trên Render.")

    for data in pending:
        session.add(User(
            **data,
            password_hash=hash_password(passwords[PASSWORD_KEYS[data["id"]]]),
        ))

    session.flush()
    return [data["username"] for data in pending]
