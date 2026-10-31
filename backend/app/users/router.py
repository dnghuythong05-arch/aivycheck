from typing import Annotated

from fastapi import APIRouter, Depends, Response, status

from ..auth.dependencies import Database, require_admin
from ..auth.schemas import UserPublic
from .models import User
from .schemas import EmployeeCreate, EmployeeList, EmployeeUpdate
from .service import (
    create_employee,
    delete_employee,
    list_employees,
    update_employee,
)


AdminUser = Annotated[User, Depends(require_admin)]

router = APIRouter(
    prefix="/api/users/employees",
    tags=["Employees"],
)


@router.delete(
    "/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def remove_employee(
    user_id: str,
    db: Database,
    admin: AdminUser,
) -> Response:
    delete_employee(db, admin, user_id)

    return Response(
        status_code=204,
        headers={"Cache-Control": "no-store"},
    )


@router.get("", response_model=EmployeeList)
def get_employees(
    db: Database,
    admin: AdminUser,
    response: Response,
) -> EmployeeList:
    response.headers["Cache-Control"] = "no-store"

    return EmployeeList(
        users=[
            UserPublic.model_validate(user)
            for user in list_employees(db)
        ]
    )


@router.post(
    "",
    response_model=UserPublic,
    status_code=status.HTTP_201_CREATED,
)
def post_employee(
    payload: EmployeeCreate,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> UserPublic:
    response.headers["Cache-Control"] = "no-store"

    return UserPublic.model_validate(
        create_employee(db, payload)
    )


@router.put("/{user_id}", response_model=UserPublic)
def put_employee(
    user_id: str,
    payload: EmployeeUpdate,
    db: Database,
    admin: AdminUser,
    response: Response,
) -> UserPublic:
    response.headers["Cache-Control"] = "no-store"

    return UserPublic.model_validate(
        update_employee(db, user_id, payload)
    )