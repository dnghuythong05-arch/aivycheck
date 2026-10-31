import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.bootstrap import bootstrap_initial_users
from app.config import Settings
from app.database import database_url
from app.security import verify_password
from app.users.models import User


@pytest.fixture
def clean_env(monkeypatch):
    for name in (
        "DATABASE_URL", "DB_HOST", "DB_PORT", "DB_NAME", "DB_USER",
        "DB_PASSWORD", "WEB_DIST_DIR",
    ):
        monkeypatch.delenv(name, raising=False)


@pytest.fixture
def app_factory(clean_env, monkeypatch):
    monkeypatch.setenv("DB_PASSWORD", "ci-only-password")
    from app.main import create_app
    return create_app


def test_local_database_config_keeps_special_password(clean_env):
    settings = Settings(_env_file=None, db_password="test@:/% local")
    url = database_url(settings)
    assert url.host == "127.0.0.1"
    assert url.database == "aivycheck"
    assert url.password == "test@:/% local"


@pytest.mark.parametrize("scheme", ["postgres", "postgresql", "postgresql+psycopg"])
def test_neon_url_keeps_ssl_and_uses_psycopg(clean_env, scheme):
    settings = Settings(
        _env_file=None,
        database_url=(
            f"{scheme}://cloud:test%40pass@db.example.com/aivycheck"
            "?sslmode=require&channel_binding=require"
        ),
        db_password="unused-local-password",
    )
    url = database_url(settings)
    assert url.drivername == "postgresql+psycopg"
    assert url.host == "db.example.com"
    assert url.password == "test@pass"
    assert dict(url.query) == {
        "sslmode": "require", "channel_binding": "require",
    }
    assert "test%40pass" not in str(settings)


@pytest.mark.parametrize("value", [
    "not-a-url", "sqlite:///local.db", "postgresql://host/db",
    "postgresql://u:p@host:invalid/db",
])
def test_invalid_cloud_url_does_not_leak_input(clean_env, value):
    with pytest.raises(ValidationError) as error:
        Settings(_env_file=None, database_url=value)
    assert value not in str(error.value)


def test_missing_database_password_fails_early(clean_env):
    with pytest.raises(ValidationError):
        Settings(_env_file=None)


def test_web_and_api_share_origin_without_masking_api_errors(app_factory, tmp_path):
    (tmp_path / "index.html").write_text("<html>web-ci</html>", encoding="utf-8")
    (tmp_path / "main.dart.js").write_text("// web-ci", encoding="utf-8")
    settings = Settings(
        _env_file=None, db_password="ci-only-password", web_dist_dir=tmp_path,
    )
    with TestClient(app_factory(settings)) as client:
        assert client.get("/").text == "<html>web-ci</html>"
        assert client.get("/main.dart.js").status_code == 200
        assert client.get("/api/health").json()["status"] == "ok"
        assert client.get("/api/auth/me").status_code == 401
        assert client.get("/api/not-a-route").status_code == 404
        assert client.get("/missing-file.js").status_code == 404


def test_local_root_still_opens_docs(app_factory):
    settings = Settings(_env_file=None, db_password="ci-only-password")
    with TestClient(app_factory(settings)) as client:
        response = client.get("/", follow_redirects=False)
        assert response.status_code == 307
        assert response.headers["location"] == "/docs"


def test_missing_web_build_fails_early(app_factory, tmp_path):
    settings = Settings(
        _env_file=None, db_password="ci-only-password", web_dist_dir=tmp_path,
    )
    with pytest.raises(RuntimeError, match="index.html"):
        app_factory(settings)


def test_cloud_bootstrap_preserves_existing_passwords(engine):
    # Database CI riêng; rollback cả việc khởi tạo sau khi kiểm tra.
    with engine.connect() as connection, connection.begin() as outer:
        with Session(bind=connection, join_transaction_mode="create_savepoint") as session:
            passwords = {
                "AIVY_ADMIN_PASSWORD": "cloud-admin-test",
                "AIVY_EMPLOYEE_PASSWORD": "cloud-employee-test",
            }
            assert bootstrap_initial_users(session, passwords) == ["aiviee", "huythong"]
            session.commit()
            admin = session.get(User, "admin_aivee")
            original_hash = admin.password_hash
            assert verify_password("cloud-admin-test", original_hash)
            assert bootstrap_initial_users(session, {}) == []
            assert bootstrap_initial_users(session, {
                "AIVY_ADMIN_PASSWORD": "different-password",
                "AIVY_EMPLOYEE_PASSWORD": "different-password",
            }) == []
            assert admin.password_hash == original_hash
        outer.rollback()


def test_cloud_bootstrap_requires_both_passwords_before_writing(engine):
    with engine.connect() as connection, connection.begin() as outer:
        with Session(bind=connection, join_transaction_mode="create_savepoint") as session:
            with pytest.raises(ValueError, match="AIVY_EMPLOYEE_PASSWORD"):
                bootstrap_initial_users(session, {
                    "AIVY_ADMIN_PASSWORD": "cloud-admin-test",
                })
            assert session.scalars(select(User.id)).all() == []
        outer.rollback()
