import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.config import Settings
from app.database import create_database_engine, get_db
from app.security import hash_password
from app.users.models import User


@pytest.fixture(scope="session")
def test_settings():
    if os.environ.get("DB_NAME") != "aivycheck_test":
        raise pytest.UsageError(
            "Bộ test cần database riêng DB_NAME=aivycheck_test. "
            "Không chạy trên database aivycheck đang sử dụng."
        )

    return Settings(_env_file=None)


@pytest.fixture(scope="session")
def engine(test_settings):
    value = create_database_engine(test_settings)

    yield value

    value.dispose()


@pytest.fixture(scope="session")
def password_hash():
    return hash_password("ci-password")


@pytest.fixture
def client(engine, test_settings, password_hash):
    from app.main import create_app

    with engine.connect() as connection:
        transaction = connection.begin()
        application = create_app(test_settings)

        def database():
            with Session(
                bind=connection,
                join_transaction_mode="create_savepoint",
            ) as session:
                yield session

        application.dependency_overrides[get_db] = database

        try:
            with Session(
                bind=connection,
                join_transaction_mode="create_savepoint",
            ) as session:
                session.add_all([
                    User(
                        id="admin_aivee",
                        username="aiviee",
                        full_name="Admin CI",
                        email="admin-ci@example.com",
                        role="admin",
                        is_active=True,
                        password_hash=password_hash,
                    ),
                    User(
                        id="employee_huythong",
                        username="huythong",
                        full_name="Employee CI",
                        email="employee-ci@example.com",
                        role="employee",
                        is_active=True,
                        password_hash=password_hash,
                    ),
                    User(
                        id="employee_other",
                        username="ci_other",
                        full_name="Other CI",
                        email="other-ci@example.com",
                        role="employee",
                        is_active=True,
                        password_hash=password_hash,
                    ),
                ])

                session.commit()

            with TestClient(application) as value:
                yield value

        finally:
            application.dependency_overrides.clear()
            transaction.rollback()


def login_headers(client, username):
    response = client.post(
        "/api/auth/login",
        json={
            "username": username,
            "password": "ci-password",
        },
    )

    assert response.status_code == 200, response.text

    return {
        "Authorization": "Bearer " + response.json()["access_token"],
    }


@pytest.fixture
def admin(client):
    return login_headers(client, "aiviee")


@pytest.fixture
def employee(client):
    return login_headers(client, "huythong")