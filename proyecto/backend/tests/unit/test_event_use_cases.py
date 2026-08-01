"""Event use case behavior."""

from datetime import UTC, datetime
from uuid import UUID

import pytest
from src.application.dtos.event_dtos import CoverImageDto, EventWriteDto
from src.application.use_cases.create_event import CreateEvent
from src.application.use_cases.delete_event import DeleteEvent
from src.application.use_cases.list_events import ListEvents
from src.application.use_cases.update_event import UpdateEvent
from src.domain.entities.event import Event
from src.domain.exceptions.event_not_found import EventNotFoundError

from tests.fakes import FakeEventImageStorage, FakeEventRepository


def event_input(*, title: str = "Linux al aire libre") -> EventWriteDto:
    return EventWriteDto(
        title=title,
        event_type="Taller",
        description="Una tarde para aprender y compartir.",
        starts_at=datetime(2026, 8, 15, 16, 0, tzinfo=UTC),
        location="Ciudad de México",
    )


def cover(*, marker: bytes = b"image") -> CoverImageDto:
    return CoverImageDto(content=marker, content_type="image/png", extension="png")


def test_create_search_update_and_delete_event() -> None:
    repository = FakeEventRepository()
    storage = FakeEventImageStorage()
    created = CreateEvent(repository=repository, image_storage=storage).run(
        data=event_input(), cover=cover()
    )

    assert created.image_path and created.image_path.startswith("/media/events/")
    assert ListEvents(repository=repository).run(query="linux") == [created]

    updated = UpdateEvent(repository=repository, image_storage=storage).run(
        event_id=created.id,
        data=event_input(title="Linux desde cero"),
        cover=cover(marker=b"new"),
        remove_cover=False,
    )
    assert updated.title == "Linux desde cero"
    assert storage.deleted

    DeleteEvent(repository=repository, image_storage=storage).run(event_id=created.id)
    assert repository.get(event_id=created.id) is None


def test_update_unknown_event_fails() -> None:
    with pytest.raises(EventNotFoundError):
        UpdateEvent(
            repository=FakeEventRepository(),
            image_storage=FakeEventImageStorage(),
        ).run(
            event_id=UUID("00000000-0000-0000-0000-000000000001"),
            data=event_input(),
            cover=None,
            remove_cover=False,
        )


def test_domain_rejects_naive_dates() -> None:
    now = datetime.now(UTC)
    with pytest.raises(ValueError, match="starts_at"):
        Event(
            id=UUID("00000000-0000-0000-0000-000000000001"),
            title="Evento válido",
            event_type="Taller",
            description="",
            starts_at=datetime(2026, 8, 1),  # noqa: DTZ001 - deliberately invalid
            location="Guadalajara",
            image_key=None,
            created_at=now,
            updated_at=now,
        )


def test_create_removes_cover_when_repository_fails() -> None:
    class FailingRepository(FakeEventRepository):
        def create(self, *, event: Event) -> Event:
            raise RuntimeError("database unavailable")

    storage = FakeEventImageStorage()
    with pytest.raises(RuntimeError):
        CreateEvent(repository=FailingRepository(), image_storage=storage).run(
            data=event_input(), cover=cover()
        )
    assert storage.images == {}
    assert len(storage.deleted) == 1


def test_update_removes_new_cover_and_preserves_old_cover_when_database_fails() -> None:
    class FailingUpdateRepository(FakeEventRepository):
        def update(self, *, event: Event) -> Event:
            raise RuntimeError("database unavailable")

    repository = FailingUpdateRepository()
    storage = FakeEventImageStorage()
    created = CreateEvent(repository=repository, image_storage=storage).run(
        data=event_input(), cover=cover(marker=b"old")
    )
    assert created.image_path is not None
    old_key = created.image_path.removeprefix("/")

    with pytest.raises(RuntimeError):
        UpdateEvent(repository=repository, image_storage=storage).run(
            event_id=created.id,
            data=event_input(title="Nuevo título"),
            cover=cover(marker=b"new"),
            remove_cover=False,
        )

    assert old_key in storage.images
    assert list(storage.images) == [old_key]
