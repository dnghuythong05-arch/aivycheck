import logging
from contextlib import asynccontextmanager
from typing import Annotated


from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import Engine, text
from sqlalchemy.exc import SQLAlchemyError

from .auth.router import router as auth_router
from .users.router import router as users_router
from .shifts.router import router as shifts_router
from .attendance_setup.router import router as attendance_setup_router
from .attendance.router import router as attendance_router
from .config import Settings, get_settings
from .database import create_database_engine, get_database_engine


logger = logging.getLogger(__name__)


def create_app(settings: Settings | None = None) -> FastAPI:
    config = settings if settings is not None else get_settings()

    @asynccontextmanager
    async def lifespan(application: FastAPI):
        application.state.db_engine = create_database_engine(config)

        try:
            yield
        finally:
            application.state.db_engine.dispose()

    application = FastAPI(
        title="AiVie.check API",
        version="0.2.0",
        lifespan=lifespan,
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:[0-9]{1,5})?",
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
    )

    application.state.settings = config
    application.include_router(auth_router)
    application.include_router(users_router)
    application.include_router(shifts_router)
    application.include_router(attendance_setup_router)
    application.include_router(attendance_router)

    if config.web_dist_dir is None:
        @application.get("/", include_in_schema=False)
        def root() -> RedirectResponse:
            return RedirectResponse(
                url="/docs",
                status_code=status.HTTP_307_TEMPORARY_REDIRECT,
            )

    @application.exception_handler(RequestValidationError)
    async def validation_error(
        _request: Request,
        error: RequestValidationError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            content={
                "detail": [
                    {
                        "loc": list(item["loc"]),
                        "msg": item["msg"],
                        "type": item["type"],
                    }
                    for item in error.errors()
                ]
            },
        )

    @application.exception_handler(SQLAlchemyError)
    async def database_error(
        _request: Request,
        error: SQLAlchemyError,
    ) -> JSONResponse:
        logger.error(
            "Database operation failed (%s)",
            type(error).__name__,
        )

        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "detail": "Chưa xử lý được dữ liệu. Hãy thử lại.",
            },
        )

    @application.get("/api/health", tags=["Health"])
    def health() -> dict[str, str]:
        return {
            "status": "ok",
            "service": "AiVie.check API",
        }

    @application.get("/api/health/db", tags=["Health"])
    def database_health(
        engine: Annotated[Engine, Depends(get_database_engine)],
    ) -> dict[str, str]:
        try:
            with engine.connect() as connection:
                connection.execute(text("SELECT 1")).scalar_one()

        except SQLAlchemyError as error:
            logger.error(
                "Database health check failed (%s)",
                type(error).__name__,
            )

            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Chưa kết nối được cơ sở dữ liệu.",
            ) from None

        return {
            "status": "ok",
            "database": "connected",
        }

    # Luôn đăng ký API trước khi mount web tại đường dẫn gốc.
    if config.web_dist_dir is not None:
        if not (config.web_dist_dir / "index.html").is_file():
            raise RuntimeError("WEB_DIST_DIR thiếu bản dựng web index.html.")
        application.mount(
            "/",
            StaticFiles(directory=config.web_dist_dir, html=True),
            name="web",
        )

    return application


app = create_app()
