"""S3 event cover storage."""

from typing import Any
from uuid import UUID, uuid4

from src.application.dtos.event_dtos import CoverImageDto
from src.application.interfaces.event_image_storage import EventImageStorage


class S3EventImageStorage(EventImageStorage):
    """Store immutable covers in the private media bucket."""

    def __init__(self, *, client: Any, bucket: str) -> None:
        self._client = client
        self._bucket = bucket

    def store(self, *, event_id: UUID, cover: CoverImageDto) -> str:
        key = f"media/events/{event_id}/{uuid4().hex}.{cover.extension}"
        self._client.put_object(
            Bucket=self._bucket,
            Key=key,
            Body=cover.content,
            ContentType=cover.content_type,
            CacheControl="public,max-age=31536000,immutable",
        )
        return key

    def delete(self, *, image_key: str) -> None:
        if not image_key.startswith("media/events/"):
            raise ValueError("Refusing to delete an object outside event media")
        self._client.delete_object(Bucket=self._bucket, Key=image_key)
