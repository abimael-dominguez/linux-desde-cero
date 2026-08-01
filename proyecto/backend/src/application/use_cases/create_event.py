"""Create event use case."""

from datetime import UTC, datetime
from uuid import uuid4

from src.application.dtos.event_dtos import CoverImageDto, EventDto, EventWriteDto
from src.application.interfaces.event_image_storage import EventImageStorage
from src.domain.entities.event import Event
from src.domain.interfaces.event_repository import EventRepository


class CreateEvent:
    """Publish a new event and optionally store its cover."""

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
        data: EventWriteDto,
        cover: CoverImageDto | None,
    ) -> EventDto:
        """Create the event and compensate a failed database write."""

        event_id = uuid4()
        now = datetime.now(UTC)
        image_key = (
            self._image_storage.store(event_id=event_id, cover=cover) if cover else None
        )
        event = Event(
            id=event_id,
            image_key=image_key,
            created_at=now,
            updated_at=now,
            **data.model_dump(),
        )
        try:
            created = self._repository.create(event=event)
        except Exception:
            if image_key:
                self._image_storage.delete(image_key=image_key)
            raise
        return EventDto.from_entity(created)
