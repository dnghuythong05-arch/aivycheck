from collections.abc import Callable
from getpass import getpass

from sqlalchemy import Engine, select
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from .config import get_settings
from .database import create_database_engine
from .security import hash_password
from .users.models import User


INITIAL_USERS = (
    {
        "id": "admin_aivee",
        "username": "aiviee",
        "full_name": "Trương Thu Thảo",
        "email": "truongaivy2863@gmail.com",
        "role": "admin",
    },
    {
        "id": "employee_huythong",
        "username": "huythong",
        "full_name": "Đặng Huy Thông",
        "email": "dnghuythong05@gmail.com",
        "role": "employee",
    },
)


def seed_initial_users(
    engine: Engine,
    password_reader: Callable[[str], str] = getpass,
) -> list[str]:
    ids = [user["id"] for user in INITIAL_USERS]

    with Session(engine) as session:
        existing = set(
            session.scalars(
                select(User.id).where(User.id.in_(ids))
            ).all()
        )

    pending = []

    for data in INITIAL_USERS:
        if data["id"] in existing:
            continue

        print(f"Tạo tài khoản {data['username']} ({data['role']}).")

        while True:
            password = password_reader("Mật khẩu đăng nhập app: ")
            confirmation = password_reader("Nhập lại mật khẩu: ")

            if password != confirmation:
                print("Hai lần nhập chưa giống nhau. Hãy nhập lại.")
                continue

            try:
                password_hash = hash_password(password)
            except ValueError as error:
                print(error)
                continue

            break

        pending.append(
            User(**data, password_hash=password_hash)
        )

    created = [user.username for user in pending]

    if pending:
        with Session(engine) as session:
            session.add_all(pending)
            session.commit()

    return created


def main() -> int:
    engine = create_database_engine(get_settings())

    try:
        created = seed_initial_users(engine)

        if created:
            print("Đã tạo: " + ", ".join(created))
        else:
            print(
                "Các tài khoản ban đầu đã tồn tại. "
                "Giữ nguyên dữ liệu."
            )

        return 0

    except (KeyboardInterrupt, EOFError):
        print("\nĐã hủy khởi tạo tài khoản.")
        return 1

    except IntegrityError:
        print("Tài khoản hoặc email bị trùng. Không ghi thay đổi.")
        return 1

    except SQLAlchemyError:
        print(
            "Chưa khởi tạo được tài khoản. "
            "Kiểm tra kết nối và chạy migration trước."
        )
        return 1

    finally:
        engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())