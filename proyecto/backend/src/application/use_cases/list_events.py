"""List and search events use case."""

from src.application.dtos.event_dtos import EventDto
from src.domain.interfaces.event_repository import EventRepository


class ListEvents:
    """Return the public event catalog."""

    def __init__(self, *, repository: EventRepository) -> None:
        self._repository = repository

    def run(self, *, query: str | None) -> list[EventDto]:
        """Normalize a bounded prefix query and return at most 100 events."""

        normalized = query.strip()[:80] if query and query.strip() else None
        return [
            EventDto.from_entity(event)
            for event in self._repository.list(query=normalized, limit=100)
        ]
