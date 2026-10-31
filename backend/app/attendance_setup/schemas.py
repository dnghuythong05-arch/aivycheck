from typing import Annotated, Literal

from pydantic import (
    AwareDatetime,
    BaseModel,
    ConfigDict,
    Field,
    field_validator,
    model_validator,
)


Number = Annotated[
    float,
    Field(allow_inf_nan=False, strict=True),
]

Sample = Annotated[
    list[Number],
    Field(min_length=1024, max_length=1024),
]


class GpsPayload(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        populate_by_name=True,
    )

    latitude: Number | None = Field(default=None, ge=-90, le=90)
    longitude: Number | None = Field(default=None, ge=-180, le=180)

    radius_meters: Number = Field(
        default=200.0,
        alias="radiusMeters",
        ge=1,
        le=5000,
    )

    @model_validator(mode="after")
    def check_center(self) -> "GpsPayload":
        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("Địa điểm phải có đủ hai tọa độ.")

        return self


class GpsResponse(BaseModel):
    gps: GpsPayload


class FacePhoto(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=255)
    key: str = Field(max_length=512)

    dataUrl: str = Field(
        max_length=60000,
        pattern=r"^data:image/jpeg;base64,[A-Za-z0-9+/]+={0,2}$",
    )


class FaceProfilePayload(BaseModel):
    model_config = ConfigDict(extra="forbid")

    model: Literal["human-3.3.6-faceres"]
    preprocessing: Literal["legacy-v1", "equalized-v1"]

    samples: list[Sample] = Field(min_length=1, max_length=10)
    photos: list[FacePhoto] = Field(default_factory=list, max_length=10)
    registeredAt: AwareDatetime

    @field_validator("samples")
    @classmethod
    def nonzero_samples(
        cls,
        rows: list[list[float]],
    ) -> list[list[float]]:
        if any(
            not any(value != 0 for value in row)
            for row in rows
        ):
            raise ValueError("Mẫu khuôn mặt không hợp lệ.")

        return rows

    @model_validator(mode="after")
    def check_photos(self) -> "FaceProfilePayload":
        if self.photos and len(self.photos) != len(self.samples):
            raise ValueError(
                "Số ảnh xem trước phải khớp số mẫu khuôn mặt."
            )

        return self


class FaceResponse(BaseModel):
    userId: str
    profile: FaceProfilePayload | None


class FaceIdsResponse(BaseModel):
    userIds: list[str]