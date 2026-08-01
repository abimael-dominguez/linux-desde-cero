"""Public event HTTP routes."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, File, Form, Query, Response, UploadFile, status

from src.application.dtos.event_dtos import CoverImageDto, EventDto, EventWriteDto
from src.infrastructure.adapters.cover_image_parser import (
    MAX_COVER_BYTES,
    parse_cover_image,
)
from src.infrastructure.config.container import ApplicationContainer


def build_event_router(*, container: ApplicationContainer) -> APIRouter:
    """Build routes that delegate all behavior to use cases."""

    router = APIRouter(prefix="/api/events", tags=["events"])

    @router.get("", response_model=list[EventDto])
    def list_events(
        q: Annotated[str | None, Query(max_length=80)] = None,
    ) -> list[EventDto]:
        return container.list_events.run(query=q)

    @router.post("", response_model=EventDto, status_code=status.HTTP_201_CREATED)
    async def create_event(
        title: Annotated[str, Form()],
        event_type: Annotated[str, Form()],
        description: Annotated[str, Form()] = "",
        starts_at: Annotated[str, Form()] = "",
        location: Annotated[str, Form()] = "",
        cover: Annotated[UploadFile | None, File()] = None,
    ) -> EventDto:
        return container.create_event.run(
            data=_write_dto(
                title=title,
                event_type=event_type,
                description=description,
                starts_at=starts_at,
                location=location,
            ),
            cover=await _read_cover(cover=cover),
        )

    @router.put("/{event_id}", response_model=EventDto)
    async def update_event(
        event_id: UUID,
        title: Annotated[str, Form()],
        event_type: Annotated[str, Form()],
        description: Annotated[str, Form()] = "",
        starts_at: Annotated[str, Form()] = "",
        location: Annotated[str, Form()] = "",
        remove_cover: Annotated[bool, Form()] = False,
        cover: Annotated[UploadFile | None, File()] = None,
    ) -> EventDto:
        return container.update_event.run(
            event_id=event_id,
            data=_write_dto(
                title=title,
                event_type=event_type,
                description=description,
                starts_at=starts_at,
                location=location,
            ),
            cover=await _read_cover(cover=cover),
            remove_cover=remove_cover,
        )

    @router.delete("/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
    def delete_event(event_id: UUID) -> Response:
        container.delete_event.run(event_id=event_id)
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    return router


def _write_dto(
    *,
    title: str,
    event_type: str,
    description: str,
    starts_at: str,
    location: str,
) -> EventWriteDto:
    return EventWriteDto(
        title=title,
        event_type=event_type,
        description=description,
        starts_at=starts_at,
        location=location,
    )


async def _read_cover(*, cover: UploadFile | None) -> CoverImageDto | None:
    if cover is None or not cover.filename:
        return None
    content = await cover.read(MAX_COVER_BYTES + 1)
    return parse_cover_image(content=content)
