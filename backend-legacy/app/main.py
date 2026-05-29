from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError

from .config import get_settings
from .database import Base, engine
from . import models as _models  # noqa: F401
from .schemas import HealthResponse, WeatherEnvelopeResponse, WeatherRequestQuery
from .security import SimpleRateLimiter, guard_weather_request
from .weather_service import WeatherContext, WeatherService, translate_kma_error
from .kma import KmaApiError


settings = get_settings()
rate_limiter = SimpleRateLimiter(limit_per_minute=settings.weather_rate_limit_per_minute)
weather_service = WeatherService(settings)


@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.auto_create_tables:
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
        except SQLAlchemyError:
            pass
    yield
    await engine.dispose()


app = FastAPI(
    title="Ppallae Backend",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["x-api-key", "content-type"],
)


def get_weather_guard():
    return guard_weather_request(settings, rate_limiter)


@app.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(
        ok=True,
        environment=settings.app_env,
        provider=settings.kma_provider_name,
    )


@app.get("/weather", response_model=WeatherEnvelopeResponse)
async def weather(
    query: WeatherRequestQuery = Depends(),
    _: None = Depends(get_weather_guard()),
) -> WeatherEnvelopeResponse:
    context = WeatherContext(
        latitude=query.lat,
        longitude=query.lng,
        source_type=query.sourceType,
        label=query.label,
    )
    try:
        payload = await weather_service.fetch_weather(context)
        return WeatherEnvelopeResponse.model_validate(payload)
    except KmaApiError as error:
        status_code, detail = translate_kma_error(error)
        raise HTTPException(status_code=status_code, detail=detail)
    except ValueError as error:
        raise HTTPException(
            status_code=500,
            detail={
                "error": {
                    "code": "BACKEND-500",
                    "stage": "response_validate",
                    "message": "Backend response validation failed.",
                    "debug": str(error),
                }
            },
        )
