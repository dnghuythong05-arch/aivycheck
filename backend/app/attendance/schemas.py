from typing import Annotated, Literal

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field


Number = Annotated[
    float,
    Field(strict=True, allow_inf_nan=False),
]


class GpsEvidence(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        populate_by_name=True,
    )

    latitude: Number = Field(ge=-90, le=90)
    longitude: Number = Field(ge=-180, le=180)
    accuracy: Number = Field(ge=0, le=150)

    captured_at: AwareDatetime = Field(alias="capturedAt")


class AttendanceAction(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        populate_by_name=True,
    )

    shift_id: str = Field(
        alias="shiftId",
        min_length=1,
        max_length=64,
    )

    request_id: str = Field(
        alias="requestId",
        min_length=16,
        max_length=80,
        pattern=r"^[A-Za-z0-9_-]+$",
    )

    gps: GpsEvidence

    # Kết quả nhận diện của trình duyệt.
    # Backend chưa tự đối chiếu embedding hoặc chứng thực webcam.
    face_verified: Literal[True] = Field(alias="faceVerified")


class AttendancePublic(BaseModel):
    id: str
    userId: str
    shiftSnapshot: dict
    checkIn: AwareDatetime
    checkOut: AwareDatetime | None


class AttendanceList(BaseModel):
    records: list[AttendancePublic]