"""DynamoDB repository tests without AWS calls."""

from dataclasses import replace
from datetime import UTC, datetime
from uuid import uuid4

from src.domain.entities.event import Event
from src.infrastructure.adapters.dynamodb_event_repository import (
    DynamoDbEventRepository,
)


class FakeTable:
    """Store DynamoDB items in memory while recording scan arguments."""

    def __init__(self) -> None:
        self.items: dict[str, dict] = {}
        self.scan_arguments: dict = {}

    def put_item(self, *, Item: dict, **_: object) -> None:
        self.items[Item["id"]] = Item

    def delete_item(self, *, Key: dict) -> None:
        self.items.pop(Key["id"], None)

    def get_item(self, *, Key: dict) -> dict:
        item = self.items.get(Key["id"])
        return {"Item": item} if item else {}

    def scan(self, **kwargs: object) -> dict:
        self.scan_arguments = kwargs
        return {"Items": list(self.items.values())}


def event(*, title: str = "Festival Linux") -> Event:
    """Create a valid event for persistence tests."""
    now = datetime(2026, 8, 1, 12, tzinfo=UTC)
    return Event(
        id=uuid4(),
        title=title,
        event_type="Taller",
        description="Terminal y contenedores.",
        starts_at=now,
        location="Mérida",
        image_key=None,
        created_at=now,
        updated_at=now,
    )


def test_crud_uses_one_item_per_event() -> None:
    table = FakeTable()
    repository = DynamoDbEventRepository(table=table)
    created = event()

    repository.create(event=created)
    assert repository.get(event_id=created.id) == created

    updated = replace(created, title="Festival actualizado")
    repository.update(event=updated)
    assert repository.get(event_id=created.id) == updated

    repository.delete(event_id=created.id)
    assert repository.get(event_id=created.id) is None


def test_search_is_limited_and_normalized() -> None:
    table = FakeTable()
    repository = DynamoDbEventRepository(table=table)
    repository.create(event=event())

    repository.list(query="  FEST  ", limit=100)

    assert table.scan_arguments["Limit"] == 100
    assert "FilterExpression" in table.scan_arguments
