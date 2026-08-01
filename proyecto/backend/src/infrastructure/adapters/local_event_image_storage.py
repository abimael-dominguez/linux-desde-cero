"""Local filesystem cover storage."""

import os
from pathlib import Path
from uuid import UUID, uuid4

from src.application.dtos.event_dtos import CoverImageDto
from src.application.interfaces.event_image_storage import EventImageStorage


class LocalEventImageStorage(EventImageStorage):
    """Store covers under the project's ignored local directory."""

    def __init__(self, *, root: Path) -> None:
        self._root = root.resolve()

    def store(self, *, event_id: UUID, cover: CoverImageDto) -> str:
        key = f"media/events/{event_id}/{uuid4().hex}.{cover.extension}"
        target = (self._root / key).resolve()
        self._assert_owned(path=target)
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_suffix(f"{target.suffix}.tmp")
        temporary.write_bytes(cover.content)
        os.replace(temporary, target)
        return key

    def delete(self, *, image_key: str) -> None:
        target = (self._root / image_key).resolve()
        self._assert_owned(path=target)
        target.unlink(missing_ok=True)

    def _assert_owned(self, *, path: Path) -> None:
        if self._root not in path.parents:
            raise ValueError("Refusing to access media outside the local storage root")
