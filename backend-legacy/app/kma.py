from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

import httpx


KST = ZoneInfo("Asia/Seoul")


class KmaApiError(Exception):
    def __init__(
        self,
        code: str,
        stage: str,
        message: str,
        *,
        debug_message: str | None = None,
        details: dict[str, str] | None = None,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.stage = stage
        self.message = message
        self.debug_message = debug_message
        self.details = details or {}


@dataclass(frozen=True)
class KmaGridPoint:
    nx: int
    ny: int


class KmaGridConverter:
    def from_lat_lng(self, latitude: float, longitude: float) -> KmaGridPoint:
        re = 6371.00877
        grid = 5.0
        slat1 = 30.0
        slat2 = 60.0
        olon = 126.0
        olat = 38.0
        xo = 43.0
        yo = 136.0

        deg_to_rad = math.pi / 180.0
        re_scaled = re / grid
        slat1_rad = slat1 * deg_to_rad
        slat2_rad = slat2 * deg_to_rad
        olon_rad = olon * deg_to_rad
        olat_rad = olat * deg_to_rad

        sn = math.tan(math.pi * 0.25 + slat2_rad * 0.5) / math.tan(math.pi * 0.25 + slat1_rad * 0.5)
        sn = math.log(math.cos(slat1_rad) / math.cos(slat2_rad)) / math.log(sn)
        sf = math.tan(math.pi * 0.25 + slat1_rad * 0.5)
        sf = math.pow(sf, sn) * math.cos(slat1_rad) / sn
        ro = math.tan(math.pi * 0.25 + olat_rad * 0.5)
        ro = re_scaled * sf / math.pow(ro, sn)

        ra = math.tan(math.pi * 0.25 + latitude * deg_to_rad * 0.5)
        ra = re_scaled * sf / math.pow(ra, sn)
        theta = longitude * deg_to_rad - olon_rad
        if theta > math.pi:
            theta -= 2.0 * math.pi
        if theta < -math.pi:
            theta += 2.0 * math.pi
        theta *= sn

        nx = math.floor(ra * math.sin(theta) + xo + 0.5)
        ny = math.floor(ro - ra * math.cos(theta) + yo + 0.5)
        return KmaGridPoint(nx=nx, ny=ny)


class KmaClient:
    def __init__(
        self,
        *,
        auth_key: str,
        ultra_ncst_url: str,
        ultra_fcst_url: str,
        village_fcst_url: str,
        timeout_seconds: int,
        provider_name: str,
    ) -> None:
        self.auth_key = auth_key
        self.ultra_ncst_url = ultra_ncst_url
        self.ultra_fcst_url = ultra_fcst_url
        self.village_fcst_url = village_fcst_url
        self.timeout_seconds = timeout_seconds
        self.provider_name = provider_name
        self.grid_converter = KmaGridConverter()

    async def fetch_bundle(self, latitude: float, longitude: float) -> tuple[dict, list[dict], dict[str, str]]:
        if not self.auth_key.strip():
            raise KmaApiError("KMA-001", "config_check", "KMA auth key is missing.")

        diagnostics = {
            "provider": self.provider_name,
            "requestTarget": "kma",
            "forecastStrategy": "ultra_fcst_then_village_fcst",
            "latitude": f"{latitude:.5f}",
            "longitude": f"{longitude:.5f}",
        }
        grid = self.grid_converter.from_lat_lng(latitude, longitude)
        diagnostics["nx"] = str(grid.nx)
        diagnostics["ny"] = str(grid.ny)

        now = datetime.now(KST)
        ncst_base = self._latest_ultra_ncst_base(now)
        ultra_base = self._latest_ultra_fcst_base(now)
        diagnostics["ncstBaseDate"] = self._format_date(ncst_base)
        diagnostics["ncstBaseTime"] = self._format_time(ncst_base)
        diagnostics["ultraBaseDate"] = self._format_date(ultra_base)
        diagnostics["ultraBaseTime"] = self._format_time(ultra_base)

        current_items = await self._fetch_items(
            request_name="ultra_ncst",
            url=self.ultra_ncst_url,
            query={
                "pageNo": "1",
                "numOfRows": "100",
                "dataType": "JSON",
                "base_date": self._format_date(ncst_base),
                "base_time": self._format_time(ncst_base),
                "nx": str(grid.nx),
                "ny": str(grid.ny),
                "authKey": self.auth_key,
            },
            diagnostics=diagnostics,
        )
        forecast_items, source = await self._fetch_forecast_items(
            now=now,
            grid=grid,
            ultra_base=ultra_base,
            diagnostics=diagnostics,
        )
        current = self._build_current_snapshot(current_items, forecast_items, diagnostics, source)
        hourly = self._build_hourly_forecasts(forecast_items, now, source, diagnostics)
        if not hourly:
            raise KmaApiError("KMA-006", "forecast_categories", "No usable forecast categories in KMA response.")
        return current, hourly[:5], diagnostics

    async def _fetch_forecast_items(
        self,
        *,
        now: datetime,
        grid: KmaGridPoint,
        ultra_base: datetime,
        diagnostics: dict[str, str],
    ) -> tuple[list[dict], str]:
        try:
            items = await self._fetch_items(
                request_name="ultra_fcst",
                url=self.ultra_fcst_url,
                query={
                    "pageNo": "1",
                    "numOfRows": "120",
                    "dataType": "JSON",
                    "base_date": self._format_date(ultra_base),
                    "base_time": self._format_time(ultra_base),
                    "nx": str(grid.nx),
                    "ny": str(grid.ny),
                    "authKey": self.auth_key,
                },
                diagnostics=diagnostics,
            )
            return items, "ultra_fcst"
        except KmaApiError:
            village_base = self._latest_village_fcst_base(now)
            diagnostics["villageBaseDate"] = self._format_date(village_base)
            diagnostics["villageBaseTime"] = self._format_time(village_base)
            items = await self._fetch_items(
                request_name="village_fcst",
                url=self.village_fcst_url,
                query={
                    "pageNo": "1",
                    "numOfRows": "300",
                    "dataType": "JSON",
                    "base_date": self._format_date(village_base),
                    "base_time": self._format_time(village_base),
                    "nx": str(grid.nx),
                    "ny": str(grid.ny),
                    "authKey": self.auth_key,
                },
                diagnostics=diagnostics,
            )
            return items, "village_fcst"

    async def _fetch_items(
        self,
        *,
        request_name: str,
        url: str,
        query: dict[str, str],
        diagnostics: dict[str, str],
    ) -> list[dict]:
        safe_query = dict(query)
        safe_query["authKey"] = "****"
        diagnostics[f"{request_name}Request"] = str(httpx.URL(url).copy_merge_params(safe_query))
        timeout = httpx.Timeout(self.timeout_seconds)
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.get(url, params=query)
        except httpx.TimeoutException as error:
            raise KmaApiError("KMA-003", f"{request_name}_http_timeout", "KMA timeout.", debug_message=str(error))
        except httpx.HTTPError as error:
            raise KmaApiError("KMA-003", f"{request_name}_http_request", "KMA request failed.", debug_message=str(error))

        diagnostics[f"{request_name}Status"] = str(response.status_code)
        diagnostics[f"{request_name}BodyPreview"] = response.text[:180]
        if response.status_code != 200:
            raise KmaApiError(
                "KMA-004",
                f"{request_name}_http_response",
                "KMA returned non-200 status.",
                debug_message=f"HTTP {response.status_code}",
            )

        try:
            decoded = response.json()
        except ValueError as error:
            raise KmaApiError("KMA-005", f"{request_name}_response_parse", "Failed to parse KMA response.", debug_message=str(error))

        response_node = decoded.get("response") or {}
        header_node = response_node.get("header") or {}
        result_code = str(header_node.get("resultCode") or "")
        result_message = str(header_node.get("resultMsg") or "")
        diagnostics[f"{request_name}ResultCode"] = result_code
        diagnostics[f"{request_name}ResultMsg"] = result_message
        if result_code and result_code != "00":
            raise KmaApiError(
                "KMA-010" if self._looks_like_auth_failure(result_code, result_message) else "KMA-005",
                f"{request_name}_response_header",
                "KMA returned error response.",
                debug_message=result_message,
            )

        items = (((response_node.get("body") or {}).get("items") or {}).get("item"))
        if isinstance(items, list):
            return [dict(item) for item in items if isinstance(item, dict)]
        if isinstance(items, dict):
            return [dict(items)]
        raise KmaApiError("KMA-006", "response_items_missing", "KMA response missing items.")

    def _build_current_snapshot(
        self,
        current_items: list[dict],
        forecast_items: list[dict],
        diagnostics: dict[str, str],
        source: str,
    ) -> dict:
        fallback_forecast = self._build_hourly_forecasts(forecast_items, datetime.now(KST), source, diagnostics)
        if not fallback_forecast:
            raise KmaApiError("KMA-006", "forecast_categories", "No forecast items to build current weather.")
        values: dict[str, str] = {}
        for item in current_items:
            category = str(item.get("category") or "")
            obsr_value = str(item.get("obsrValue") or "")
            if category:
                values[category] = obsr_value
        first = fallback_forecast[0]["weather"]
        return {
            "temperatureCelsius": self._double_value(values.get("T1H"), float(first["temperatureCelsius"])),
            "humidity": self._int_value(values.get("REH"), int(first["humidity"])),
            "windSpeedMps": self._double_value(values.get("WSD"), float(first["windSpeedMps"])),
            "skyCondition": self._sky_condition(self._sky_code_for(first["skyCondition"]), values.get("PTY")),
            "rainProbability": int(first["rainProbability"]),
        }

    def _build_hourly_forecasts(
        self,
        items: list[dict],
        now: datetime,
        source: str,
        diagnostics: dict[str, str],
    ) -> list[dict]:
        grouped: dict[str, dict[str, str]] = {}
        for item in items:
            fcst_date = str(item.get("fcstDate") or "")
            fcst_time = str(item.get("fcstTime") or "")
            category = str(item.get("category") or "")
            fcst_value = str(item.get("fcstValue") or "")
            if not fcst_date or not fcst_time or not category:
                continue
            grouped.setdefault(f"{fcst_date}{fcst_time}", {})[category] = fcst_value

        results: list[dict] = []
        for key in sorted(grouped.keys()):
            forecast_at = self._parse_forecast_datetime(key)
            if forecast_at is None or forecast_at < now:
                continue
            values = grouped[key]
            if not self._has_forecast_categories(values):
                continue
            results.append(
                {
                    "at": forecast_at.isoformat(),
                    "weather": {
                        "temperatureCelsius": self._double_value(self._temperature_value(values, source), 20.0),
                        "humidity": self._int_value(values.get("REH"), 55),
                        "windSpeedMps": self._double_value(values.get("WSD"), 1.5),
                        "skyCondition": self._sky_condition(values.get("SKY"), values.get("PTY")),
                        "rainProbability": self._int_value(values.get("POP"), 20),
                    },
                }
            )
        return results

    def _has_forecast_categories(self, values: dict[str, str]) -> bool:
        return (
            ("T1H" in values or "TMP" in values)
            and "REH" in values
            and "WSD" in values
            and "PTY" in values
            and "SKY" in values
            and "POP" in values
        )

    def _temperature_value(self, values: dict[str, str], source: str) -> str | None:
        if source == "village_fcst":
            return values.get("TMP") or values.get("T1H")
        return values.get("T1H") or values.get("TMP")

    def _double_value(self, value: str | None, fallback: float) -> float:
        try:
            return float(value) if value is not None else fallback
        except ValueError:
            return fallback

    def _int_value(self, value: str | None, fallback: int) -> int:
        try:
            return int(float(value)) if value is not None else fallback
        except ValueError:
            return fallback

    def _sky_condition(self, sky_value: str | None, pty_value: str | None) -> str:
        if pty_value and pty_value != "0":
            return "rainy"
        if sky_value == "1":
            return "sunny"
        if sky_value == "3":
            return "partlyCloudy"
        if sky_value == "4":
            return "cloudy"
        return "partlyCloudy"

    def _sky_code_for(self, condition: str) -> str:
        if condition == "sunny":
            return "1"
        if condition == "partlyCloudy":
            return "3"
        return "4"

    def _parse_forecast_datetime(self, key: str) -> datetime | None:
        if len(key) != 12:
            return None
        try:
            year = int(key[0:4])
            month = int(key[4:6])
            day = int(key[6:8])
            hour = int(key[8:10])
            minute = int(key[10:12])
            return datetime(year, month, day, hour, minute, tzinfo=KST)
        except ValueError:
            return None

    def _latest_ultra_ncst_base(self, now: datetime) -> datetime:
        aligned = now.replace(minute=0, second=0, microsecond=0)
        if now.minute < 45:
            return aligned - timedelta(hours=1)
        return aligned

    def _latest_ultra_fcst_base(self, now: datetime) -> datetime:
        aligned = now.replace(minute=30, second=0, microsecond=0)
        if now.minute < 45:
            return aligned - timedelta(hours=1)
        return aligned

    def _latest_village_fcst_base(self, now: datetime) -> datetime:
        candidates = [23, 20, 17, 14, 11, 8, 5, 2]
        adjusted = now - timedelta(hours=1) if now.minute < 10 else now
        for hour in candidates:
            if adjusted.hour > hour or (adjusted.hour == hour and adjusted.minute >= 10):
                return adjusted.replace(hour=hour, minute=0, second=0, microsecond=0)
        previous_day = adjusted - timedelta(days=1)
        return previous_day.replace(hour=23, minute=0, second=0, microsecond=0)

    def _format_date(self, value: datetime) -> str:
        return value.strftime("%Y%m%d")

    def _format_time(self, value: datetime) -> str:
        return value.strftime("%H%M")

    def _looks_like_auth_failure(self, result_code: str, result_message: str) -> bool:
        normalized = result_message.lower()
        return (
            result_code == "30"
            or "servicekey" in normalized
            or "auth" in normalized
            or "key" in normalized
            or "unauthorized" in normalized
            or "forbidden" in normalized
        )
