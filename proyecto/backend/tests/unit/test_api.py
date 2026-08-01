"""Public HTTP API tests."""

from io import BytesIO
from pathlib import Path

from fastapi.testclient import TestClient
from PIL import Image
from src.application.use_cases.create_event import CreateEvent
from src.application.use_cases.delete_event import DeleteEvent
from src.application.use_cases.list_events import ListEvents
from src.application.use_cases.update_event import UpdateEvent
from src.infrastructure.api.app import create_app
from src.infrastructure.config.container import ApplicationContainer
from src.infrastructure.config.settings import Settings

from tests.fakes import FakeEventImageStorage, FakeEventRepository


def client() -> TestClient:
    repository = FakeEventRepository()
    storage = FakeEventImageStorage()
    settings = Settings(
        dynamodb_table="unused",
        dynamodb_endpoint_url=None,
        file_storage_backend="s3",
        local_media_root=Path(".local"),
        media_bucket="fake-media",
        aws_region="us-east-1",
    )
    container = ApplicationContainer(
        settings=settings,
        create_event=CreateEvent(repository=repository, image_storage=storage),
        list_events=ListEvents(repository=repository),
        update_event=UpdateEvent(repository=repository, image_storage=storage),
        delete_event=DeleteEvent(repository=repository, image_storage=storage),
    )
    return TestClient(create_app(container=container))


def cover_bytes() -> bytes:
    stream = BytesIO()
    Image.new("RGB", (20, 20), color="#1ea7a1").save(stream, format="WEBP")
    return stream.getvalue()


def test_public_crud_flow() -> None:
    api = client()
    form = {
        "title": "Festival Linux",
        "event_type": "Encuentro",
        "description": "Comunidad, terminal y café.",
        "starts_at": "2026-09-10T18:00:00-06:00",
        "location": "Mérida",
    }
    created = api.post(
        "/api/events",
        data=form,
        files={"cover": ("cover.webp", cover_bytes(), "image/webp")},
    )
    assert created.status_code == 201
    event = created.json()
    assert event["image_path"].startswith("/media/events/")
    assert api.get("/api/events", params={"q": "festi"}).json()[0]["id"] == event["id"]

    updated = api.put(
        f"/api/events/{event['id']}",
        data={**form, "title": "Festival Linux 2026", "remove_cover": "true"},
    )
    assert updated.status_code == 200
    assert updated.json()["image_path"] is None
    assert api.delete(f"/api/events/{event['id']}").status_code == 204
    assert api.delete(f"/api/events/{event['id']}").status_code == 404


def test_invalid_cover_returns_422() -> None:
    response = client().post(
        "/api/events",
        data={
            "title": "Evento válido",
            "event_type": "Taller",
            "starts_at": "2026-09-10T18:00:00-06:00",
            "location": "Puebla",
        },
        files={"cover": ("bad.png", b"not-image", "image/png")},
    )
    assert response.status_code == 422
