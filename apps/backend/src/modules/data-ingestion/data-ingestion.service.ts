import { Inject, Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CacheService } from '../../cache/cache.service';
import { WEATHER_PROVIDER } from '../weather/weather.module';
import { AIR_QUALITY_PROVIDER } from '../air-quality/air-quality.module';
import {
  WeatherBundle,
  WeatherProvider,
} from '../weather/types';
import {
  AirQualityProvider,
  AirQualitySnapshot,
} from '../air-quality/types';
import {
  CACHE_KEY,
  CACHE_TTL,
  IngestAirQualityPayload,
  IngestWeatherPayload,
} from './data-ingestion.constants';

@Injectable()
export class DataIngestionService {
  private readonly logger = new Logger(DataIngestionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cache: CacheService,
    @Inject(WEATHER_PROVIDER) private readonly weather: WeatherProvider,
    @Inject(AIR_QUALITY_PROVIDER) private readonly airQuality: AirQualityProvider,
  ) {}

  async ingestWeather(payload: IngestWeatherPayload): Promise<WeatherBundle> {
    const bundle = await this.weather.fetchBundle({
      nx: payload.nx,
      ny: payload.ny,
    });

    await this.prisma.weatherSnapshot.create({
      data: {
        regionId: payload.regionId,
        temperatureC: bundle.current.temperatureC,
        humidityPercent: bundle.current.humidityPercent,
        windSpeedMps: bundle.current.windSpeedMps,
        precipType: bundle.current.precipType,
        skyCondition: bundle.current.skyCondition,
        observedAt: bundle.current.observedAt,
        source: bundle.source,
      },
    });

    if (bundle.hourly.length > 0) {
      await this.prisma.$transaction(
        bundle.hourly.map((h) =>
          this.prisma.weatherForecastHourly.upsert({
            where: {
              regionId_forecastAt: {
                regionId: payload.regionId,
                forecastAt: h.forecastAt,
              },
            },
            update: {
              temperatureC: h.temperatureC,
              humidityPercent: h.humidityPercent,
              windSpeedMps: h.windSpeedMps,
              precipType: h.precipType,
              precipitationProbability: h.precipitationProbability,
              skyCondition: h.skyCondition,
              source: bundle.source,
            },
            create: {
              regionId: payload.regionId,
              forecastAt: h.forecastAt,
              temperatureC: h.temperatureC,
              humidityPercent: h.humidityPercent,
              windSpeedMps: h.windSpeedMps,
              precipType: h.precipType,
              precipitationProbability: h.precipitationProbability,
              skyCondition: h.skyCondition,
              source: bundle.source,
            },
          }),
        ),
      );
    }

    await this.cache.set(
      CACHE_KEY.weatherCurrent(payload.regionId),
      bundle.current,
      CACHE_TTL.WEATHER_CURRENT_SECONDS,
    );
    await this.cache.set(
      CACHE_KEY.weatherForecast(payload.regionId),
      bundle.hourly,
      CACHE_TTL.WEATHER_FORECAST_SECONDS,
    );

    this.logger.log(
      `weather ingested region=${payload.regionId} source=${bundle.source} hourly=${bundle.hourly.length}`,
    );
    return bundle;
  }

  async ingestAirQuality(
    payload: IngestAirQualityPayload,
  ): Promise<AirQualitySnapshot> {
    const snapshot = await this.airQuality.fetchByRegion({
      sido: payload.sido,
      sigungu: payload.sigungu,
    });

    await this.prisma.airQualitySnapshot.create({
      data: {
        regionId: payload.regionId,
        pm10Value: snapshot.pm10Value,
        pm10Grade: snapshot.pm10Grade,
        pm25Value: snapshot.pm25Value,
        pm25Grade: snapshot.pm25Grade,
        stationName: snapshot.stationName,
        observedAt: snapshot.observedAt,
      },
    });

    await this.cache.set(
      CACHE_KEY.airQuality(payload.regionId),
      snapshot,
      CACHE_TTL.AIR_QUALITY_SECONDS,
    );

    this.logger.log(
      `air-quality ingested region=${payload.regionId} pm10=${snapshot.pm10Value} pm25=${snapshot.pm25Value}`,
    );
    return snapshot;
  }
}
