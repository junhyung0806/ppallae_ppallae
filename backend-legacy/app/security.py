from collections import defaultdict, deque
from collections.abc import Callable
from datetime import datetime, timedelta, UTC

from fastapi import HTTPException, Request, status

from .config import Settings


class SimpleRateLimiter:
    def __init__(self, limit_per_minute: int) -> None:
        self.limit_per_minute = limit_per_minute
        self._buckets: dict[str, deque[datetime]] = defaultdict(deque)

    def check(self, key: str) -> None:
        now = datetime.now(UTC)
        window_start = now - timedelta(minutes=1)
        bucket = self._buckets[key]
        while bucket and bucket[0] < window_start:
            bucket.popleft()
        if len(bucket) >= self.limit_per_minute:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many weather requests. Try again shortly.",
            )
        bucket.append(now)


def client_ip_from_request(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for", "").strip()
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "unknown"


def verify_weather_api_key(settings: Settings, request: Request) -> None:
    if not settings.weather_service_api_key:
        return
    provided = request.headers.get("x-api-key", "").strip()
    if provided != settings.weather_service_api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid weather service api key.",
        )


def guard_weather_request(
    settings: Settings,
    limiter: SimpleRateLimiter,
) -> Callable[[Request], None]:
    def _guard(request: Request) -> None:
        verify_weather_api_key(settings, request)
        limiter.check(client_ip_from_request(request))

    return _guard
