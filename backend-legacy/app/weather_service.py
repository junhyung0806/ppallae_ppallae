from __future__ import annotations

from dataclasses import dataclass
from typing import Any
from uuid import uuid4

from cachetools import TTLCache

from .config import Settings
from .kma import KmaApiError, KmaClient


@dataclass(frozen=True)
class WeatherContext:
    latitude: float
    longitude: float
    source_type: str
    label: str

    @property
    def cache_key(self) -> str:
        return f"{self.source_type}:{self.label}:{self.latitude:.5f}:{self.longitude:.5f}"


class WeatherService:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.cache: TTLCache[str, dict[str, Any]] = TTLCache(maxsize=512, ttl=settings.weather_cache_ttl_seconds)
        self.kma_client = KmaClient(
            auth_key=settings.kma_auth_key,
            ultra_ncst_url=settings.kma_ultra_srt_ncst_url,
            ultra_fcst_url=settings.kma_ultra_srt_fcst_url,
            village_fcst_url=settings.kma_vilage_fcst_url,
            timeout_seconds=settings.weather_http_timeout_seconds,
            provider_name=settings.kma_provider_name,
        )

    async def fetch_weather(self, context: WeatherContext) -> dict[str, Any]:
        cached = self.cache.get(context.cache_key)
        if cached is not None:
            return cached

        trace_id = uuid4().hex
        current, hourly, diagnostics = await self.kma_client.fetch_bundle(
            latitude=context.latitude,
            longitude=context.longitude,
        )
        payload = {
            "current": current,
            "hourly": hourly,
            "meta": {
                "source": "kma-proxy",
                "stage": "backend_success",
                "userMessage": "외부 날씨 백엔드 데이터로 추천을 표시 중입니다.",
                "provider": self.settings.kma_provider_name,
                "traceId": trace_id,
                "debug": diagnostics.get("forecastStrategy"),
            },
        }
        self.cache[context.cache_key] = payload
        return payload


def translate_kma_error(error: KmaApiError) -> tuple[int, dict[str, Any]]:
    if error.code in {"KMA-001", "KMA-010"}:
        status_code = 502
    elif error.code == "KMA-003":
        status_code = 504
    elif error.code == "KMA-004":
        status_code = 502
    else:
        status_code = 500
    return status_code, {
        "error": {
            "code": error.code,
            "stage": error.stage,
            "message": error.message,
            "debug": error.debug_message,
            "details": error.details,
        }
    }

