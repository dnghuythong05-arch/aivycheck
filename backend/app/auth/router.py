from fastapi import APIRouter, HTTPException, Request, Response, status

from .dependencies import CurrentSession, CurrentUser, Database
from .schemas import LoginRequest, LoginResponse, UserPublic
from .service import authenticate_user, create_session, revoke_session


router = APIRouter(
    prefix="/api/auth",
    tags=["Auth"],
)


@router.post("/login", response_model=LoginResponse)
def login(
    payload: LoginRequest,
    request: Request,
    response: Response,
    db: Database,
) -> LoginResponse:
    user = authenticate_user(
        db,
        payload.username,
        payload.password.get_secret_value(),
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Tài khoản hoặc mật khẩu chưa đúng.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    public_user = UserPublic.model_validate(user)

    token, expires_at = create_session(
        db,
        user,
        request.app.state.settings.session_hours,
    )

    response.headers["Cache-Control"] = "no-store"

    return LoginResponse(
        access_token=token,
        expires_at=expires_at,
        user=public_user,
    )


@router.get("/me", response_model=UserPublic)
def me(
    user: CurrentUser,
    response: Response,
) -> UserPublic:
    response.headers["Cache-Control"] = "no-store"
    return UserPublic.model_validate(user)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(
    session: CurrentSession,
    db: Database,
) -> Response:
    revoke_session(db, session)
    return Response(status_code=status.HTTP_204_NO_CONTENT)