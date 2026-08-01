"""Uploaded image validation."""

from io import BytesIO

from PIL import Image, UnidentifiedImageError

from src.application.dtos.event_dtos import CoverImageDto

MAX_COVER_BYTES = 2 * 1024 * 1024
_FORMATS = {
    "JPEG": ("jpg", "image/jpeg"),
    "PNG": ("png", "image/png"),
    "WEBP": ("webp", "image/webp"),
}


def parse_cover_image(*, content: bytes) -> CoverImageDto:
    """Verify bytes with Pillow and return canonical metadata."""

    if not content or len(content) > MAX_COVER_BYTES:
        raise ValueError("Cover image must be between 1 byte and 2 MiB")
    try:
        with Image.open(BytesIO(content)) as image:
            image.verify()
            image_format = image.format
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as error:
        raise ValueError("Cover must be a valid JPG, PNG or WebP image") from error
    if image_format not in _FORMATS:
        raise ValueError("Cover must be a JPG, PNG or WebP image")
    extension, content_type = _FORMATS[image_format]
    return CoverImageDto(
        content=content,
        content_type=content_type,
        extension=extension,
    )
