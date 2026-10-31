from datetime import datetime

from pydantic import (
    AwareDatetime,
    BaseModel,
    ConfigDict,
    Field,
    field_validator,
    model_validator,
)


class ShiftFields(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=40)
    start: AwareDatetime
    end: AwareDatetime

    @field_validator("name", mode="before")
    @classmethod
    def normalize_name(cls, value: object) -> str:
        if not isinstance(value, str):
            raise ValueError("Hãy nhập tên ca làm.")

        return value.strip()

    @model_validator(mode="after")
    def check_times(self) -> "ShiftFields":
        if self.end <= self.start:
            raise ValueError("Giờ kết thúc phải sau giờ bắt đầu.")

        return self


class ShiftCreate(ShiftFields):
    user_id: str = Field(alias="userId", min_length=1, max_length=64)


class ShiftUpdate(ShiftFields):
    pass


class ShiftPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str = Field(serialization_alias="userId")
    name: str
    starts_at: datetime = Field(serialization_alias="start")
    ends_at: datetime = Field(serialization_alias="end")
    is_deleted: bool = Field(serialization_alias="isDeleted")


class ShiftList(BaseModel):
    shifts: list[ShiftPublic]


class LegacyShift(ShiftCreate):
    legacy_id: str = Field(alias="legacyId", min_length=1, max_length=64)
    is_deleted: bool = Field(default=False, alias="isDeleted")


class ShiftImportRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    shifts: list[LegacyShift] = Field(min_length=1, max_length=200)


class ShiftMapping(BaseModel):
    legacyId: str
    shift: ShiftPublic


class ShiftImportResponse(BaseModel):
    mappings: list[ShiftMapping]