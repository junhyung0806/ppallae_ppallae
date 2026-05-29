import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CacheService } from '../../cache/cache.service';
import { DataIngestionService } from '../data-ingestion/data-ingestion.service';
import { CACHE_KEY } from '../data-ingestion/data-ingestion.constants';
import { WeatherCurrent, WeatherHourly } from '../weather/types';
import { AirQualitySnapshot } from '../air-quality/types';

const STALE_THRESHOLD_MS = 90 * 60 * 1000; // 90분

export interface RegionRef {
  id: string;
  nx: number;
  ny: number;
  sido: string;
  sigungu: string;
}

export interface WeatherQueryResult {
  current: WeatherCurrent;
  hourly: WeatherHourly[];
  airQuality: AirQualitySnapshot | null;
  sources: string[];
  stale: boolean;
  generatedAt: Date;
}

@Injectable()
export class WeatherQueryService {
  private readonly logger = new Logger(WeatherQueryService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cache: CacheService,
    private readonly ingestion: DataIngestionService,
  ) {}

  async getForRegion(region: RegionRef): Promise<WeatherQueryResult> {
    const sources: string[] = [];
    let stale = false;

    let current = await this.cache.get<WeatherCurrent>(
      CACHE_KEY.weatherCurrent(region.id),
    );
    let hourly = await this.cache.get<WeatherHourly[]>(
      CACHE_KEY.weatherForecast(region.id),
    );

    // 캐시 미스 → 온디맨드 수집
    if (!current || !hourly) {
      try {
        const bundle = await this.ingestion.ingestWeather({
          regionId: region.id,
          nx: region.nx,
          ny: region.ny,
        });
        current = bundle.current;
        hourly = bundle.hourly;
        sources.push(bundle.source);
      } catch (e) {
        this.logger.warn(
          `on-demand weather ingestion failed for ${region.id}: ${(e as Error).message}`,
        );
        // 폴백: DB 최신 데이터
        const fallback = await this.loadLatestFromDb(region.id);
        current = fallback.current;
        hourly = fallback.hourly;
        stale = true;
        if (fallback.source) sources.push(fallback.source);
      }
    } else {
      sources.push('cache');
    }

    if (!current) {
      const fallback = await this.loadLatestFromDb(region.id);
      current = fallback.current;
      hourly = fallback.hourly ?? [];
      stale = true;
      if (fallback.source) sources.push(fallback.source);
    }

    if (current) {
      const age = Date.now() - new Date(current.observedAt).getTime();
      if (age > STALE_THRESHOLD_MS) stale = true;
    }

    // 미세먼지
    let airQuality = await this.cache.get<AirQualitySnapshot>(
      CACHE_KEY.airQuality(region.id),
    );
    if (!airQuality) {
      try {
        airQuality = await this.ingestion.ingestAirQuality({
          regionId: region.id,
          sido: region.sido,
          sigungu: region.sigungu,
        });
        sources.push('airquality');
      } catch (e) {
        this.logger.warn(
          `on-demand air-quality ingestion failed for ${region.id}: ${(e as Error).message}`,
        );
        airQuality = await this.loadLatestAirFromDb(region.id);
      }
    }

    return {
      current: current!,
      hourly: hourly ?? [],
      airQuality,
      sources: dedupe(sources),
      stale,
      generatedAt: new Date(),
    };
  }

  private async loadLatestFromDb(regionId: string): Promise<{
    current: WeatherCurrent | null;
    hourly: WeatherHourly[] | null;
    source: string | null;
  }> {
    const snapshot = await this.prisma.weatherSnapshot.findFirst({
      where: { regionId },
      orderBy: { observedAt: 'desc' },
    });
    const forecasts = await this.prisma.weatherForecastHourly.findMany({
      where: { regionId, forecastAt: { gte: new Date() } },
      orderBy: { forecastAt: 'asc' },
      take: 24,
    });

    if (!snapshot) return { current: null, hourly: null, source: null };

    return {
      current: {
        temperatureC: snapshot.temperatureC,
        humidityPercent: snapshot.humidityPercent,
        windSpeedMps: snapshot.windSpeedMps,
        precipType: snapshot.precipType as WeatherCurrent['precipType'],
        precipitationProbability: 0,
        skyCondition: snapshot.skyCondition as WeatherCurrent['skyCondition'],
        observedAt: snapshot.observedAt,
      },
      hourly: forecasts.map((f) => ({
        temperatureC: f.temperatureC,
        humidityPercent: f.humidityPercent,
        windSpeedMps: f.windSpeedMps,
        precipType: f.precipType as WeatherCurrent['precipType'],
        precipitationProbability: f.precipitationProbability,
        skyCondition: f.skyCondition as WeatherCurrent['skyCondition'],
        observedAt: snapshot.observedAt,
        forecastAt: f.forecastAt,
      })),
      source: `db:${snapshot.source}`,
    };
  }

  private async loadLatestAirFromDb(
    regionId: string,
  ): Promise<AirQualitySnapshot | null> {
    const row = await this.prisma.airQualitySnapshot.findFirst({
      where: { regionId },
      orderBy: { observedAt: 'desc' },
    });
    if (!row) return null;
    return {
      pm10Value: row.pm10Value,
      pm10Grade: row.pm10Grade,
      pm25Value: row.pm25Value,
      pm25Grade: row.pm25Grade,
      stationName: row.stationName,
      observedAt: row.observedAt,
    };
  }
}

function dedupe(arr: string[]): string[] {
  return Array.from(new Set(arr));
}
