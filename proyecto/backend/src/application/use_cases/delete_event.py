"""Delete event use case."""

from uuid import UUID

from src.application.interfaces.event_image_storage import EventImageStorage
from src.domain.exceptions.event_not_found import EventNotFoundError
from src.domain.interfaces.event_repository import EventRepository


class DeleteEvent:
    """Permanently remove an event and its cover."""

    def __init__(
        self,
        *,
        repository: EventRepository,
        image_storage: EventImageStorage,
    ) -> None:
        self._repository = repository
        self._image_storage = image_storage

    def run(self, *, event_id: UUID) -> None:
        """Delete an existing event."""

        current = self._repository.get(event_id=event_id)
        if current is None:
            raise EventNotFoundError(f"Event {event_id} was not found")
        self._repository.delete(event_id=event_id)
        if current.image_key:
            self._image_storage.delete(image_key=current.image_key)
