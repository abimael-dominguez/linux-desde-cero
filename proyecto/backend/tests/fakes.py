"""In-memory adapters for application and HTTP tests."""

from uuid import UUID

from src.application.dtos.event_dtos import CoverImageDto
from src.application.interfaces.event_image_storage import EventImageStorage
from src.domain.entities.event import Event
from src.domain.interfaces.event_repository import EventRepository


class FakeEventRepository(EventRepository):
    """Deterministic event repository."""

    def __init__(self) -> None:
        self.events: dict[UUID, Event] = {}

    def create(self, *, event: Event) -> Event:
        self.events[event.id] = event
        return event

    def update(self, *, event: Event) -> Event:
        self.events[event.id] = event
        return event

    def delete(self, *, event_id: UUID) -> None:
        self.events.pop(event_id, None)

    def get(self, *, event_id: UUID) -> Event | None:
        return self.events.get(event_id)

    def list(self, *, query: str | None, limit: int) -> list[Event]:
        values = sorted(self.events.values(), key=lambda event: event.starts_at)
        if query:
            lowered = query.lower()
            values = [
                event
                for event in values
                if event.title.lower().startswith(lowered)
                or event.location.lower().startswith(lowered)
            ]
        return values[:limit]


class FakeEventImageStorage(EventImageStorage):
    """Track image writes and removals in memory."""

    def __init__(self) -> None:
        self.images: dict[str, bytes] = {}
        self.deleted: list[str] = []
        self._sequence = 0

    def store(self, *, event_id: UUID, cover: CoverImageDto) -> str:
        self._sequence += 1
        key = f"media/events/{event_id}/cover-{self._sequence}.{cover.extension}"
        self.images[key] = cover.content
        return key

    def delete(self, *, image_key: str) -> None:
        self.images.pop(image_key, None)
        self.deleted.append(image_key)
