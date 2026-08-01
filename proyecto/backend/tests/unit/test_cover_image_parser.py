"""Cover validation tests."""

from io import BytesIO

import pytest
from PIL import Image
from src.infrastructure.adapters.cover_image_parser import (
    MAX_COVER_BYTES,
    parse_cover_image,
)


def png_bytes() -> bytes:
    stream = BytesIO()
    Image.new("RGB", (12, 12), color="#0d4777").save(stream, format="PNG")
    return stream.getvalue()


def test_parser_uses_verified_image_format() -> None:
    parsed = parse_cover_image(content=png_bytes())
    assert parsed.extension == "png"
    assert parsed.content_type == "image/png"


@pytest.mark.parametrize(
    "content", [b"", b"not-an-image", b"x" * (MAX_COVER_BYTES + 1)]
)
def test_parser_rejects_invalid_content(content: bytes) -> None:
    with pytest.raises(ValueError):
        parse_cover_image(content=content)
