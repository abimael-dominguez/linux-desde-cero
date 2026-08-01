"""FastAPI application factory."""

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import ValidationError

from src.domain.exceptions.event_not_found import EventNotFoundError
from src.infrastructure.api.routes import build_event_router
from src.infrastructure.config.container import ApplicationContainer
from src.infrastructure.config.settings import Settings


def create_app(*, container: ApplicationContainer | None = None) -> FastAPI:
    """Create the inbound HTTP adapter with injected use cases."""

    resolved = container or ApplicationContainer.build(
        settings=Settings.from_environment()
    )
    app = FastAPI(title="Eventos Cero", version="1.0.0", docs_url="/api/docs")
    app.include_router(build_event_router(container=resolved))

    @app.exception_handler(EventNotFoundError)
    async def event_not_found(
        _request: Request,
        error: EventNotFoundError,
    ) -> JSONResponse:
        return JSONResponse(status_code=404, content={"detail": str(error)})

    @app.exception_handler(ValidationError)
    async def invalid_dto(_request: Request, error: ValidationError) -> JSONResponse:
        return JSONResponse(status_code=422, content={"detail": error.errors()})

    @app.exception_handler(ValueError)
    async def invalid_value(_request: Request, error: ValueError) -> JSONResponse:
        return JSONResponse(status_code=422, content={"detail": str(error)})

    if resolved.settings.file_storage_backend == "local":
        media_directory = resolved.settings.local_media_root / "media"
        media_directory.mkdir(parents=True, exist_ok=True)
        app.mount("/media", StaticFiles(directory=media_directory), name="media")
    return app
