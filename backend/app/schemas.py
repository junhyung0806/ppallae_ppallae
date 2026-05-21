from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class WeatherRequestQuery(BaseModel):
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    sourceType: Literal["current", "search", "saved"]
    label: str = Field(..., min_length=1, max_length=120)


class WeatherSnapshotResponse(BaseModel):
    temperatureCelsius: float
    humidity: int
    windSpeedMps: float
    skyCondition: Literal["sunny", "partlyCloudy", "cloudy", "rainy"]
    rainProbability: int


class HourlyWeatherResponse(BaseModel):
    at: datetime
    weather: WeatherSnapshotResponse


class WeatherMetaResponse(BaseModel):
    source: str
    stage: str
    userMessage: str
    provider: str | None = None
    traceId: str | None = None
    debug: str | None = None


class WeatherEnvelopeResponse(BaseModel):
    current: WeatherSnapshotResponse
    hourly: list[HourlyWeatherResponse]
    meta: WeatherMetaResponse


class HealthResponse(BaseModel):
    ok: bool
    environment: str
    provider: str

