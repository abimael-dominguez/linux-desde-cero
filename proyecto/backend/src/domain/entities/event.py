"""Published event entity."""

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass(frozen=True, slots=True)
class Event:
    """A public event announcement."""

    id: UUID
    title: str
    event_type: str
    description: str
    starts_at: datetime
    location: str
    image_key: str | None
    created_at: datetime
    updated_at: datetime

    def __post_init__(self) -> None:
        """Reject invalid state at the domain boundary."""

        limits = {
            "title": (self.title, 3, 120),
            "event_type": (self.event_type, 3, 60),
            "description": (self.description, 0, 600),
            "location": (self.location, 3, 160),
        }
        for field_name, (value, minimum, maximum) in limits.items():
            normalized = value.strip()
            if len(normalized) < minimum or len(normalized) > maximum:
                raise ValueError(
                    f"{field_name} must contain between {minimum} and {maximum} characters"
                )
            object.__setattr__(self, field_name, normalized)
        for field_name, value in (
            ("starts_at", self.starts_at),
            ("created_at", self.created_at),
            ("updated_at", self.updated_at),
        ):
            if value.tzinfo is None or value.utcoffset() is None:
                raise ValueError(f"{field_name} must include a time zone")
        if self.image_key is not None and not self.image_key.startswith(
            "media/events/"
        ):
            raise ValueError("image_key must belong to the event media namespace")
