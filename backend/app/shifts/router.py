from typing import Annotated

from fastapi import APIRouter, Depends, Query, Response, status

from ..auth.dependencies import CurrentUser, Database, require_admin
from ..users.models import User
from .schemas import (
    ShiftCreate,
    ShiftImportRequest,
    ShiftImportResponse,
    ShiftList,
    ShiftMapping,
    ShiftPublic,
    ShiftUpdate,
)
from .service import (
    create_shift,
    delete_shift,
    import_shifts,
    list_shifts,
    update_shift,
)


AdminUser = Annotated[User, Depends(require_admin)]

router = APIRouter(prefix="/api/shifts", tags=["Shifts"])


@router.get("", response_model=ShiftList)
def get_shifts(
    db: Database,
    user: CurrentUser,
    response: Response,
    user_id: Annotated[
        str | None,
        Query(alias="userId", min_length=1, max_length=64),
    ] = None,
) -> ShiftList:
    response.headers["Cache-Control"] = "no-store"

    return ShiftList(
        shifts=[
            ShiftPublic.model_validate(row)
            for row in list_shifts(db, user, user_id)
        ]
    )


@router.post("/import", response_model=ShiftImportResponse)
def import_legacy_shifts(
    payload: ShiftImportRequest,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> ShiftImportResponse:
    response.headers["Cache-Control"] = "no-store"

    return ShiftImportResponse(
        mappings=[
            ShiftMapping(
                legacyId=key,
                shift=ShiftPublic.model_validate(row),
            )
            for key, row in import_shifts(db, admin, payload.shifts)
        ]
    )


@router.post(
    "",
    response_model=ShiftPublic,
    status_code=status.HTTP_201_CREATED,
)
def post_shift(
    payload: ShiftCreate,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> ShiftPublic:
    response.headers["Cache-Control"] = "no-store"

    return ShiftPublic.model_validate(
        create_shift(db, admin, payload)
    )


@router.put("/{shift_id}", response_model=ShiftPublic)
def put_shift(
    shift_id: str,
    payload: ShiftUpdate,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> ShiftPublic:
    response.headers["Cache-Control"] = "no-store"

    return ShiftPublic.model_validate(
        update_shift(db, admin, shift_id, payload)
    )


@router.delete(
    "/{shift_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def remove_shift(
    shift_id: str,
    db: Database,
    admin: AdminUser,
) -> Response:
    delete_shift(db, admin, shift_id)

    return Response(status_code=status.HTTP_204_NO_CONTENT)