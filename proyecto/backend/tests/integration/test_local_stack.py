"""Full local stack test with DynamoDB Local and filesystem covers."""

import os
from io import BytesIO
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from PIL import Image
from src.infrastructure.api.app import create_app
from src.infrastructure.config.container import ApplicationContainer
from src.infrastructure.config.settings import Settings

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_DYNAMODB_INTEGRATION") != "1",
    reason="set RUN_DYNAMODB_INTEGRATION=1 after starting Compose",
)


def image_bytes(*, color: str) -> bytes:
    stream = BytesIO()
    Image.new("RGB", (24, 24), color=color).save(stream, format="WEBP")
    return stream.getvalue()


def test_complete_api_crud_with_real_local_adapters(tmp_path: Path) -> None:
    settings = Settings(
        dynamodb_table=os.environ["DYNAMODB_TABLE"],
        dynamodb_endpoint_url=os.environ["DYNAMODB_ENDPOINT_URL"],
        file_storage_backend="local",
        local_media_root=tmp_path,
        media_bucket="",
        aws_region="us-east-1",
    )
    api = TestClient(
        create_app(container=ApplicationContainer.build(settings=settings))
    )
    form = {
        "title": "Cumbre Linux Local",
        "event_type": "Taller",
        "description": "CRUD real",
        "starts_at": "2026-10-05T17:00:00-06:00",
        "location": "Querétaro",
    }

    created = api.post(
        "/api/events",
        data=form,
        files={"cover": ("first.webp", image_bytes(color="#207f79"), "image/webp")},
    )
    assert created.status_code == 201
    first = created.json()
    first_file = tmp_path / first["image_path"].lstrip("/")
    assert first_file.is_file()
    assert api.get("/api/events", params={"q": "cumbre"}).json()[0]["id"] == first["id"]

    replaced = api.put(
        f"/api/events/{first['id']}",
        data={**form, "title": "Cumbre Linux Editada"},
        files={"cover": ("second.webp", image_bytes(color="#e46b3f"), "image/webp")},
    )
    assert replaced.status_code == 200
    second = replaced.json()
    second_file = tmp_path / second["image_path"].lstrip("/")
    assert not first_file.exists()
    assert second_file.is_file()

    without_cover = api.put(
        f"/api/events/{first['id']}",
        data={**form, "title": "Cumbre Linux Editada", "remove_cover": "true"},
    )
    assert without_cover.status_code == 200
    assert without_cover.json()["image_path"] is None
    assert not second_file.exists()
    assert api.delete(f"/api/events/{first['id']}").status_code == 204
    assert api.get("/api/events", params={"q": "cumbre"}).json() == []
