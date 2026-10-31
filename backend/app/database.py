from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy import URL, Engine, create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import DeclarativeBase, Session

from .config import Settings


class Base(DeclarativeBase):
    pass


def database_url(settings: Settings) -> URL:
    if settings.database_url is not None:
        return make_url(settings.database_url.get_secret_value()).set(
            drivername="postgresql+psycopg",
        )

    assert settings.db_password is not None
    return URL.create(
        drivername="postgresql+psycopg",
        username=settings.db_user,
        password=settings.db_password.get_secret_value(),
        host=settings.db_host,
        port=settings.db_port,
        database=settings.db_name,
    )


def create_database_engine(settings: Settings) -> Engine:
    return create_engine(
        database_url(settings),
        pool_pre_ping=True,
        pool_timeout=5,
        connect_args={"connect_timeout": 5},
    )


def get_database_engine(request: Request) -> Engine:
    return request.app.state.db_engine


def get_db(
    engine: Annotated[Engine, Depends(get_database_engine)],
) -> Iterator[Session]:
    with Session(engine) as session:
        yield session
