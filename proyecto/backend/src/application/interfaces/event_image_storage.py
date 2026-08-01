"""Event image storage contract."""

from abc import ABC, abstractmethod
from uuid import UUID

from src.application.dtos.event_dtos import CoverImageDto


class EventImageStorage(ABC):
    """Store and remove event-owned cover images."""

    @abstractmethod
    def store(self, *, event_id: UUID, cover: CoverImageDto) -> str:
        """Store a cover and return its canonical key."""

    @abstractmethod
    def delete(self, *, image_key: str) -> None:
        """Idempotently remove one cover."""
