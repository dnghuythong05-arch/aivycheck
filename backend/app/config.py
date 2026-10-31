from functools import lru_cache
from pathlib import Path
from typing import Self

from pydantic import Field, SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import make_url
from sqlalchemy.exc import ArgumentError


BACKEND_DIR = Path(__file__).resolve().parents[1]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
        hide_input_in_errors=True,
    )

    db_host: str = "127.0.0.1"
    db_port: int = Field(default=5432, ge=1, le=65535)
    db_name: str = "aivycheck"
    db_user: str = "aivycheck_app"
    db_password: SecretStr | None = Field(default=None, min_length=1)
    database_url: SecretStr | None = Field(default=None, min_length=1)
    web_dist_dir: Path | None = None

    session_hours: int = Field(default=12, ge=1, le=168)

    @model_validator(mode="after")
    def check_database(self) -> Self:
        if self.database_url is None:
            if self.db_password is None:
                raise ValueError("Cần cấu hình DB_PASSWORD hoặc DATABASE_URL.")
            return self

        try:
            url = make_url(self.database_url.get_secret_value())
            valid = (
                url.drivername in {"postgres", "postgresql", "postgresql+psycopg"}
                and url.host and url.database and url.username and url.password
                and (url.port is None or 1 <= url.port <= 65535)
            )
        except (ArgumentError, ValueError):
            valid = False

        if not valid:
            raise ValueError("DATABASE_URL phải là URL PostgreSQL hợp lệ.")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
