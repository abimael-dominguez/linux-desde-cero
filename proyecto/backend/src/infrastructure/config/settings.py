"""Environment-backed runtime settings."""

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True, slots=True)
class Settings:
    """Validated adapter selection and connection settings."""

    dynamodb_table: str
    dynamodb_endpoint_url: str | None
    file_storage_backend: str
    local_media_root: Path
    media_bucket: str
    aws_region: str

    @classmethod
    def from_environment(cls) -> "Settings":
        """Load settings without importing them into inner layers."""

        settings = cls(
            dynamodb_table=os.getenv("DYNAMODB_TABLE", "events-cero-local"),
            dynamodb_endpoint_url=os.getenv("DYNAMODB_ENDPOINT_URL") or None,
            file_storage_backend=os.getenv("FILE_STORAGE_BACKEND", "local"),
            local_media_root=Path(os.getenv("LOCAL_MEDIA_ROOT", ".local")),
            media_bucket=os.getenv("MEDIA_BUCKET", ""),
            aws_region=os.getenv("AWS_REGION", "us-east-1"),
        )
        settings.validate()
        return settings

    def validate(self) -> None:
        """Reject incomplete adapter configurations."""

        if self.file_storage_backend not in {"local", "s3"}:
            raise ValueError("FILE_STORAGE_BACKEND must be local or s3")
        if not self.dynamodb_table:
            raise ValueError("DYNAMODB_TABLE is required for DynamoDB")
        if self.file_storage_backend == "s3" and not self.media_bucket:
            raise ValueError("MEDIA_BUCKET is required for S3 storage")
