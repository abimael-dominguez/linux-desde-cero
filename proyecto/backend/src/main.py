"""ASGI entry point for local development."""

from src.infrastructure.api.app import create_app

app = create_app()
