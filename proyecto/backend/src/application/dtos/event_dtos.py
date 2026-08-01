"""Typed event input and output boundaries."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

from src.domain.entities.event import Event


class EventWriteDto(BaseModel):
    """Validated data used by create and update commands."""

    model_config = ConfigDict(str_strip_whitespace=True)

    title: str = Field(min_length=3, max_length=120)
    event_type: str = Field(min_length=3, max_length=60)
    description: str = Field(default="", max_length=600)
    starts_at: datetime
    location: str = Field(min_length=3, max_length=160)

    @field_validator("starts_at")
    @classmethod
    def require_time_zone(cls, value: datetime) -> datetime:
        """Require an unambiguous instant."""

        if value.tzinfo is None or value.utcoffset() is None:
            raise ValueError("starts_at must include a time zone")
        return value


class CoverImageDto(BaseModel):
    """A verified event cover ready for storage."""

    content: bytes
    content_type: str
    extension: str


class EventDto(BaseModel):
    """Application-level event output."""

    id: UUID
    title: str
    event_type: str
    description: str
    starts_at: datetime
    location: str
    image_path: str | None
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_entity(cls, event: Event) -> "EventDto":
        """Map the domain entity to its public representation."""

        return cls(
            id=event.id,
            title=event.title,
            event_type=event.event_type,
            description=event.description,
            starts_at=event.starts_at,
            location=event.location,
            image_path=f"/{event.image_key}" if event.image_key else None,
            created_at=event.created_at,
            updated_at=event.updated_at,
        )
