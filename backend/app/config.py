from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: str = Field(default="development", alias="APP_ENV")
    app_host: str = Field(default="0.0.0.0", alias="APP_HOST")
    app_port: int = Field(default=8081, alias="APP_PORT")
    app_cors_origins: str = Field(default="http://localhost:8080", alias="APP_CORS_ORIGINS")
    app_trusted_proxy_headers: bool = Field(default=False, alias="APP_TRUSTED_PROXY_HEADERS")

    database_url: str = Field(
        default="postgresql+asyncpg://ppallae:ppallae@localhost:5432/ppallae",
        alias="DATABASE_URL",
    )
    auto_create_tables: bool = Field(default=True, alias="AUTO_CREATE_TABLES")

    weather_service_api_key: str = Field(default="", alias="WEATHER_SERVICE_API_KEY")
    weather_rate_limit_per_minute: int = Field(default=90, alias="WEATHER_RATE_LIMIT_PER_MINUTE")
    weather_cache_ttl_seconds: int = Field(default=600, alias="WEATHER_CACHE_TTL_SECONDS")
    weather_http_timeout_seconds: int = Field(default=10, alias="WEATHER_HTTP_TIMEOUT_SECONDS")

    kma_provider_name: str = Field(default="KMA API Hub", alias="KMA_PROVIDER_NAME")
    kma_auth_key: str = Field(default="", alias="KMA_AUTH_KEY")
    kma_ultra_srt_ncst_url: str = Field(
        default="https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getUltraSrtNcst",
        alias="KMA_ULTRA_SRT_NCST_URL",
    )
    kma_ultra_srt_fcst_url: str = Field(
        default="https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getUltraSrtFcst",
        alias="KMA_ULTRA_SRT_FCST_URL",
    )
    kma_vilage_fcst_url: str = Field(
        default="https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getVilageFcst",
        alias="KMA_VILAGE_FCST_URL",
    )

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.app_cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()

