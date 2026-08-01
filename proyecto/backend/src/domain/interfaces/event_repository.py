"""Event persistence contract."""

from abc import ABC, abstractmethod
from uuid import UUID

from src.domain.entities.event import Event


class EventRepository(ABC):
    """Persistence operations required by event use cases."""

    @abstractmethod
    def create(self, *, event: Event) -> Event:
        """Persist a new event."""

    @abstractmethod
    def update(self, *, event: Event) -> Event:
        """Replace a persisted event."""

    @abstractmethod
    def delete(self, *, event_id: UUID) -> None:
        """Delete an event."""

    @abstractmethod
    def get(self, *, event_id: UUID) -> Event | None:
        """Return an event when it exists."""

    @abstractmethod
    def list(self, *, query: str | None, limit: int) -> list[Event]:
        """List events ordered by their start date."""
