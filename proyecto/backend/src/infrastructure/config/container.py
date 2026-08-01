"""Application composition root."""

from dataclasses import dataclass
from typing import Any

import boto3

from src.application.use_cases.create_event import CreateEvent
from src.application.use_cases.delete_event import DeleteEvent
from src.application.use_cases.list_events import ListEvents
from src.application.use_cases.update_event import UpdateEvent
from src.infrastructure.adapters.dynamodb_event_repository import (
    DynamoDbEventRepository,
)
from src.infrastructure.adapters.local_event_image_storage import (
    LocalEventImageStorage,
)
from src.infrastructure.adapters.s3_event_image_storage import S3EventImageStorage
from src.infrastructure.config.settings import Settings


@dataclass(frozen=True, slots=True)
class ApplicationContainer:
    """Fully wired use cases and settings."""

    settings: Settings
    create_event: CreateEvent
    list_events: ListEvents
    update_event: UpdateEvent
    delete_event: DeleteEvent

    @classmethod
    def build(
        cls,
        *,
        settings: Settings,
        aws_session: Any | None = None,
    ) -> "ApplicationContainer":
        """Select concrete adapters at the infrastructure boundary."""

        session = aws_session or boto3.session.Session(region_name=settings.aws_region)
        repository = DynamoDbEventRepository(
            table=session.resource(
                "dynamodb",
                endpoint_url=settings.dynamodb_endpoint_url,
            ).Table(settings.dynamodb_table),
        )
        if settings.file_storage_backend == "local":
            image_storage = LocalEventImageStorage(root=settings.local_media_root)
        else:
            image_storage = S3EventImageStorage(
                client=session.client("s3"),
                bucket=settings.media_bucket,
            )
        return cls(
            settings=settings,
            create_event=CreateEvent(
                repository=repository,
                image_storage=image_storage,
            ),
            list_events=ListEvents(repository=repository),
            update_event=UpdateEvent(
                repository=repository,
                image_storage=image_storage,
            ),
            delete_event=DeleteEvent(
                repository=repository,
                image_storage=image_storage,
            ),
        )
