"""Render: migration, khởi tạo tài khoản còn thiếu, rồi chạy web/API."""

import os
import sys
from pathlib import Path

from alembic import command
from alembic.config import Config
from alembic.util.exc import CommandError
from pydantic import ValidationError
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.bootstrap import bootstrap_initial_users
from app.config import get_settings
from app.database import create_database_engine


def main() -> int:
    engine = None
    try:
        port = int(os.environ.get("PORT", "8000"))
        if not 1 <= port <= 65535:
            raise ValueError("PORT không hợp lệ.")

        settings = get_settings()
        if settings.web_dist_dir is None or not (
            settings.web_dist_dir / "index.html"
        ).is_file():
            raise ValueError("Chưa có bản dựng web trong WEB_DIST_DIR.")

        os.chdir(Path(__file__).resolve().parent)
        command.upgrade(Config("alembic.ini"), "head")

        engine = create_database_engine(settings)
        with Session(engine) as session, session.begin():
            created = bootstrap_initial_users(session, os.environ)
        print(f"Cloud sẵn sàng; đã tạo {len(created)} tài khoản ban đầu.", flush=True)

    except (ValidationError, ValueError, SQLAlchemyError, CommandError) as error:
        # Không in URL kết nối, mật khẩu hoặc tham số SQL vào log cloud.
        print(
            f"Khởi động thất bại ({type(error).__name__}). "
            "Kiểm tra DATABASE_URL, WEB_DIST_DIR và mật khẩu khởi tạo.",
            file=sys.stderr,
            flush=True,
        )
        return 1
    finally:
        if engine is not None:
            engine.dispose()

    os.execv(sys.executable, [
        sys.executable, "-m", "uvicorn", "app.main:app",
        "--host", "0.0.0.0", "--port", str(port),
    ])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
