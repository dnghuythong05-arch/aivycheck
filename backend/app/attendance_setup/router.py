from typing import Annotated

from fastapi import APIRouter, Depends, Response

from ..auth.dependencies import (
    CurrentUser,
    Database,
    require_admin,
)
from ..users.models import User
from .schemas import (
    FaceIdsResponse,
    FaceProfilePayload,
    FaceResponse,
    GpsPayload,
    GpsResponse,
)
from .service import (
    clear_gps,
    face_ids,
    read_face,
    read_gps,
    save_face,
    save_gps,
)


AdminUser = Annotated[User, Depends(require_admin)]

router = APIRouter(
    prefix="/api",
    tags=["Attendance setup"],
)


def private_response(response: Response) -> None:
    response.headers["Cache-Control"] = "no-store"


@router.get("/settings/gps", response_model=GpsResponse)
def get_gps(
    db: Database,
    user: CurrentUser,
    response: Response,
) -> GpsResponse:
    private_response(response)

    return GpsResponse(gps=read_gps(db))


@router.put("/settings/gps", response_model=GpsResponse)
def put_gps(
    payload: GpsPayload,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> GpsResponse:
    private_response(response)

    return GpsResponse(gps=save_gps(db, payload))


@router.post("/settings/gps/import", response_model=GpsResponse)
def import_gps(
    payload: GpsPayload,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> GpsResponse:
    private_response(response)

    return GpsResponse(
        gps=save_gps(db, payload, importing=True),
    )


@router.delete("/settings/gps", response_model=GpsResponse)
def delete_gps(
    db: Database,
    admin: AdminUser,
    response: Response,
) -> GpsResponse:
    private_response(response)

    return GpsResponse(gps=clear_gps(db))


@router.get("/faces", response_model=FaceIdsResponse)
def get_face_ids(
    db: Database,
    admin: AdminUser,
    response: Response,
) -> FaceIdsResponse:
    private_response(response)

    return FaceIdsResponse(userIds=face_ids(db, admin))


@router.get("/faces/me", response_model=FaceResponse)
def get_own_face(
    db: Database,
    user: CurrentUser,
    response: Response,
) -> FaceResponse:
    private_response(response)

    return FaceResponse(
        userId=user.id,
        profile=read_face(db, user, user.id),
    )


@router.get("/faces/{user_id}", response_model=FaceResponse)
def get_face(
    user_id: str,
    db: Database,
    user: CurrentUser,
    response: Response,
) -> FaceResponse:
    private_response(response)

    return FaceResponse(
        userId=user_id,
        profile=read_face(db, user, user_id),
    )


@router.put("/faces/{user_id}", response_model=FaceResponse)
def put_face(
    user_id: str,
    payload: FaceProfilePayload,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> FaceResponse:
    private_response(response)

    return FaceResponse(
        userId=user_id,
        profile=save_face(db, admin, user_id, payload),
    )


@router.post("/faces/{user_id}/import", response_model=FaceResponse)
def import_face(
    user_id: str,
    payload: FaceProfilePayload,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> FaceResponse:
    private_response(response)

    return FaceResponse(
        userId=user_id,
        profile=save_face(
            db,
            admin,
            user_id,
            payload,
            importing=True,
        ),
    )


@router.delete("/faces/{user_id}", response_model=FaceResponse)
def delete_face(
    user_id: str,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> FaceResponse:
    private_response(response)

    return FaceResponse(
        userId=user_id,
        profile=save_face(db, admin, user_id, None),
    )