import re

from pydantic import BaseModel, ConfigDict, Field, SecretStr, field_validator

from ..auth.schemas import UserPublic


class EmployeeFields(BaseModel):
    model_config = ConfigDict(extra="forbid")

    username: str = Field(min_length=1, max_length=64)
    full_name: str = Field(alias="fullName", min_length=1, max_length=120)
    email: str = Field(min_length=1, max_length=254)

    @field_validator("username", "full_name", "email", mode="before")
    @classmethod
    def normalize_text(cls, value: object) -> str:
        if not isinstance(value, str):
            raise ValueError("Hãy nhập thông tin dạng chữ.")

        return value.strip()

    @field_validator("username")
    @classmethod
    def validate_username(cls, value: str) -> str:
        value = value.lower()

        if not re.fullmatch(r"[a-z0-9_]+", value):
            raise ValueError(
                "Tài khoản chỉ dùng chữ, số và dấu gạch dưới."
            )

        return value

    @field_validator("email")
    @classmethod
    def validate_email(cls, value: str) -> str:
        value = value.lower()

        if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", value):
            raise ValueError("Hãy nhập email hợp lệ.")

        return value


class EmployeeCreate(EmployeeFields):
    password: SecretStr = Field(min_length=1, max_length=128)


class EmployeeUpdate(EmployeeFields):
    password: SecretStr | None = Field(
        default=None,
        min_length=1,
        max_length=128,
    )


class EmployeeList(BaseModel):
    users: list[UserPublic]