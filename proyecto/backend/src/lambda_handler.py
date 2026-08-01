"""AWS Lambda entry point."""

from mangum import Mangum

from src.infrastructure.api.app import create_app

handler = Mangum(create_app(), lifespan="off")
