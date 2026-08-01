"""Minimal DynamoDB event repository for AWS."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from boto3.dynamodb.conditions import Attr

from src.domain.entities.event import Event
from src.domain.interfaces.event_repository import EventRepository


class DynamoDbEventRepository(EventRepository):
    """Persist one event per item using only ``id`` as the table key."""

    def __init__(self, *, table: Any) -> None:
        self._table = table

    def create(self, *, event: Event) -> Event:
        self._table.put_item(
            Item=self._item(event),
            ConditionExpression="attribute_not_exists(id)",
        )
        return event

    def update(self, *, event: Event) -> Event:
        self._table.put_item(
            Item=self._item(event),
            ConditionExpression="attribute_exists(id)",
        )
        return event

    def delete(self, *, event_id: UUID) -> None:
        self._table.delete_item(Key={"id": str(event_id)})

    def get(self, *, event_id: UUID) -> Event | None:
        item = self._table.get_item(Key={"id": str(event_id)}).get("Item")
        return self._event(item) if item else None

    def list(self, *, query: str | None, limit: int) -> list[Event]:
        arguments: dict[str, Any] = {"Limit": limit}
        if query:
            normalized = query.strip().lower()
            arguments["FilterExpression"] = Attr("title_search").begins_with(
                normalized
            ) | Attr("location_search").begins_with(normalized)
        response = self._table.scan(**arguments)
        events = [self._event(item) for item in response.get("Items", [])]
        return sorted(events, key=lambda event: (event.starts_at, event.created_at))

    @staticmethod
    def _item(event: Event) -> dict[str, Any]:
        item: dict[str, Any] = {
            "id": str(event.id),
            "title": event.title,
            "title_search": event.title.lower(),
            "event_type": event.event_type,
            "description": event.description,
            "starts_at": event.starts_at.isoformat(),
            "location": event.location,
            "location_search": event.location.lower(),
            "created_at": event.created_at.isoformat(),
            "updated_at": event.updated_at.isoformat(),
        }
        if event.image_key:
            item["image_key"] = event.image_key
        return item

    @staticmethod
    def _event(item: dict[str, Any]) -> Event:
        return Event(
            id=UUID(item["id"]),
            title=item["title"],
            event_type=item["event_type"],
            description=item["description"],
            starts_at=datetime.fromisoformat(item["starts_at"]),
            location=item["location"],
            image_key=item.get("image_key"),
            created_at=datetime.fromisoformat(item["created_at"]),
            updated_at=datetime.fromisoformat(item["updated_at"]),
        )
