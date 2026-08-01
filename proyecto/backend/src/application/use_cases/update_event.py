"""Update event use case."""

from datetime import UTC, datetime
from uuid import UUID

from src.application.dtos.event_dtos import CoverImageDto, EventDto, EventWriteDto
from src.application.interfaces.event_image_storage import EventImageStorage
from src.domain.entities.event import Event
from src.domain.exceptions.event_not_found import EventNotFoundError
from src.domain.interfaces.event_repository import EventRepository


class UpdateEvent:
    """Replace event data and coordinate cover lifecycle."""

    def __init__(
        self,
        *,
        repository: EventRepository,
        image_storage: EventImageStorage,
    ) -> None:
        self._repository = repository
        self._image_storage = image_storage

    def run(
        self,
        *,
        event_id: UUID,
        data: EventWriteDto,
        cover: CoverImageDto | None,
        remove_cover: bool,
    ) -> EventDto:
        """Update an event, preserving the old cover unless explicitly changed."""

        current = self._repository.get(event_id=event_id)
        if current is None:
            raise EventNotFoundError(f"Event {event_id} was not found")

        new_key = (
            self._image_storage.store(event_id=event_id, cover=cover) if cover else None
        )
        image_key = (
            new_key if new_key else (None if remove_cover else current.image_key)
        )
        event = Event(
            id=current.id,
            image_key=image_key,
            created_at=current.created_at,
            updated_at=datetime.now(UTC),
            **data.model_dump(),
        )
        try:
            updated = self._repository.update(event=event)
        except Exception:
            if new_key:
                self._image_storage.delete(image_key=new_key)
            raise

        if current.image_key and current.image_key != image_key:
            self._image_storage.delete(image_key=current.image_key)
        return EventDto.from_entity(updated)
