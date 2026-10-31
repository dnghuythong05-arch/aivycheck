from typing import Annotated

from fastapi import APIRouter, Depends, Query, Response

from ..auth.dependencies import (
    CurrentUser,
    Database,
    require_admin,
)
from ..users.models import User
from .schemas import (
    AttendanceAction,
    AttendanceList,
    AttendancePublic,
)
from .service import (
    delete_record,
    list_records,
    public,
    record_action,
)


router = APIRouter(
    prefix="/api/attendance",
    tags=["Attendance"],
)

AdminUser = Annotated[User, Depends(require_admin)]


@router.get("", response_model=AttendanceList)
def history(
    db: Database,
    user: CurrentUser,
    response: Response,
    user_id: Annotated[
        str | None,
        Query(
            alias="userId",
            min_length=1,
            max_length=64,
        ),
    ] = None,
) -> AttendanceList:
    response.headers["Cache-Control"] = "no-store"

    return AttendanceList(
        records=[
            public(row)
            for row in list_records(db, user, user_id)
        ]
    )


@router.post("/check-in", response_model=AttendancePublic)
def check_in(
    payload: AttendanceAction,
    db: Database,
    user: CurrentUser,
    response: Response,
):
    response.headers["Cache-Control"] = "no-store"

    return public(
        record_action(
            db,
            user,
            payload,
            checking_out=False,
        )
    )


@router.post("/check-out", response_model=AttendancePublic)
def check_out(
    payload: AttendanceAction,
    db: Database,
    user: CurrentUser,
    response: Response,
):
    response.headers["Cache-Control"] = "no-store"

    return public(
        record_action(
            db,
            user,
            payload,
            checking_out=True,
        )
    )


@router.delete("/{shift_id}", status_code=204)
def remove(
    shift_id: str,
    db: Database,
    admin: AdminUser,
) -> Response:
    delete_record(db, admin, shift_id)

    return Response(status_code=204)