export const DATA_INGESTION_QUEUE = 'data-ingestion';

export const INGEST_JOB = {
  WEATHER_CURRENT: 'ingest:weather:current',
  WEATHER_FORECAST: 'ingest:weather:forecast',
  AIR_QUALITY: 'ingest:air-quality',
  WEATHER_FANOUT: 'ingest:weather:fanout',
  AIR_QUALITY_FANOUT: 'ingest:air-quality:fanout',
} as const;

export type IngestJobName = (typeof INGEST_JOB)[keyof typeof INGEST_JOB];

export interface IngestWeatherPayload {
  regionId: string;
  nx: number;
  ny: number;
}

export interface IngestAirQualityPayload {
  regionId: string;
  sido: string;
  sigungu?: string;
}

export const CACHE_TTL = {
  WEATHER_CURRENT_SECONDS: 30 * 60,
  WEATHER_FORECAST_SECONDS: 60 * 60,
  AIR_QUALITY_SECONDS: 60 * 60,
} as const;

export const CACHE_KEY = {
  weatherCurrent: (regionId: string) => `weather:current:${regionId}`,
  weatherForecast: (regionId: string) => `weather:forecast:${regionId}`,
  airQuality: (regionId: string) => `airquality:${regionId}`,
};
