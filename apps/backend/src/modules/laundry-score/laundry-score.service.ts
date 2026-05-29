import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  ScoreInput,
  ScoreResult,
  DryingPlace,
  LaundryAmount,
  LaundryTypeCode,
  WeatherInput,
} from './types';
import { calculateLaundryScore } from './score-calculator';
import { aggregateDaily, DailySummary } from './daily-aggregator';
import { PrecipType, SkyCondition } from './types';
import {
  WeatherQueryService,
  RegionRef,
} from '../weather-query/weather-query.service';
import { RegionsService } from '../regions/regions.service';
import { WeatherCurrent, WeatherHourly } from '../weather/types';
import { AirQualitySnapshot } from '../air-quality/types';

export interface WeatherSummary {
  temperatureC: number;
  humidityPercent: number;
  windSpeedMps: number;
  precipType: string;
  skyCondition: string;
  pm10Grade: number | null;
  pm25Grade: number | null;
}

export interface ScoreEnvelope {
  region: {
    admCode: string;
    displayName: string;
    nx: number;
    ny: number;
  };
  generatedAt: string;
  source: string[];
  stale: boolean;
  weather: WeatherSummary;
  score: ScoreResult;
}

export interface TimelineEnvelope {
  region: ScoreEnvelope['region'];
  generatedAt: string;
  source: string[];
  stale: boolean;
  bestStartTimeRange: string | null;
  timeline: Array<{
    forecastAt: string;
    hourOfDay: number;
    overallScore: number;
    grade: string;
    estimatedDryHoursMin: number;
    estimatedDryHoursMax: number;
    temperatureC: number;
    humidityPercent: number;
    precipType: string;
    skyCondition: string;
  }>;
}

export interface DailyEnvelope {
  region: ScoreEnvelope['region'];
  generatedAt: string;
  source: string[];
  stale: boolean;
  days: DailySummary[];
}

@Injectable()
export class LaundryScoreService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly regions: RegionsService,
    private readonly weatherQuery: WeatherQueryService,
  ) {}

  private async getBaseDryHours(
    laundryTypeCode: LaundryTypeCode,
  ): Promise<{ min: number; max: number }> {
    const laundryType = await this.prisma.laundryType.findUnique({
      where: { code: laundryTypeCode },
    });
    if (!laundryType) {
      throw new NotFoundException(`LaundryType not found: ${laundryTypeCode}`);
    }
    return {
      min: laundryType.baseDryHoursMin,
      max: laundryType.baseDryHoursMax,
    };
  }

  calculateRaw(
    weather: WeatherInput,
    hourOfDay: number,
    dryingPlace: DryingPlace,
    laundryTypeCode: LaundryTypeCode,
    laundryAmount: LaundryAmount,
    baseDryHoursMin: number,
    baseDryHoursMax: number,
  ): ScoreResult {
    const input: ScoreInput = {
      weather,
      hourOfDay,
      dryingPlace,
      laundryTypeCode,
      laundryAmount,
      baseDryHoursMin,
      baseDryHoursMax,
    };
    return calculateLaundryScore(input);
  }

  async estimate(params: {
    weather: WeatherInput;
    hourOfDay: number;
    dryingPlace: DryingPlace;
    laundryTypeCode: LaundryTypeCode;
    laundryAmount: LaundryAmount;
  }): Promise<ScoreResult> {
    const base = await this.getBaseDryHours(params.laundryTypeCode);
    return this.calculateRaw(
      params.weather,
      params.hourOfDay,
      params.dryingPlace,
      params.laundryTypeCode,
      params.laundryAmount,
      base.min,
      base.max,
    );
  }

  async current(params: {
    regionCode: string;
    laundryTypeCode: LaundryTypeCode;
    dryingPlace: DryingPlace;
    laundryAmount: LaundryAmount;
  }): Promise<ScoreEnvelope> {
    const region = await this.regions.findByCode(params.regionCode);
    const regionRef: RegionRef = {
      id: region.id,
      nx: region.nx,
      ny: region.ny,
      sido: region.sido,
      sigungu: region.sigungu,
    };
    const weatherResult = await this.weatherQuery.getForRegion(regionRef);
    const base = await this.getBaseDryHours(params.laundryTypeCode);

    const weather = toWeatherInput(
      weatherResult.current,
      weatherResult.airQuality,
    );
    const score = this.calculateRaw(
      weather,
      new Date().getHours(),
      params.dryingPlace,
      params.laundryTypeCode,
      params.laundryAmount,
      base.min,
      base.max,
    );

    return {
      region: {
        admCode: region.admCode,
        displayName: `${region.sido} ${region.sigungu} ${region.eupmyeondong}`,
        nx: region.nx,
        ny: region.ny,
      },
      generatedAt: weatherResult.generatedAt.toISOString(),
      source: weatherResult.sources,
      stale: weatherResult.stale,
      weather: {
        temperatureC: weatherResult.current.temperatureC,
        humidityPercent: weatherResult.current.humidityPercent,
        windSpeedMps: weatherResult.current.windSpeedMps,
        precipType: weatherResult.current.precipType,
        skyCondition: weatherResult.current.skyCondition,
        pm10Grade: weatherResult.airQuality?.pm10Grade ?? null,
        pm25Grade: weatherResult.airQuality?.pm25Grade ?? null,
      },
      score,
    };
  }

  async timeline(params: {
    regionCode: string;
    laundryTypeCode: LaundryTypeCode;
    dryingPlace: DryingPlace;
  }): Promise<TimelineEnvelope> {
    const region = await this.regions.findByCode(params.regionCode);
    const regionRef: RegionRef = {
      id: region.id,
      nx: region.nx,
      ny: region.ny,
      sido: region.sido,
      sigungu: region.sigungu,
    };
    const weatherResult = await this.weatherQuery.getForRegion(regionRef);
    const base = await this.getBaseDryHours(params.laundryTypeCode);

    const timeline = weatherResult.hourly.map((h) => {
      const weather = toWeatherInput(h, weatherResult.airQuality);
      const hourOfDay = new Date(h.forecastAt).getHours();
      const score = this.calculateRaw(
        weather,
        hourOfDay,
        params.dryingPlace,
        params.laundryTypeCode,
        LaundryAmount.MEDIUM,
        base.min,
        base.max,
      );
      return {
        forecastAt: new Date(h.forecastAt).toISOString(),
        hourOfDay,
        overallScore: score.overallScore,
        grade: score.grade,
        estimatedDryHoursMin: score.estimatedDryHoursMin,
        estimatedDryHoursMax: score.estimatedDryHoursMax,
        temperatureC: h.temperatureC,
        humidityPercent: h.humidityPercent,
        precipType: h.precipType,
        skyCondition: h.skyCondition,
      };
    });

    return {
      region: {
        admCode: region.admCode,
        displayName: `${region.sido} ${region.sigungu} ${region.eupmyeondong}`,
        nx: region.nx,
        ny: region.ny,
      },
      generatedAt: weatherResult.generatedAt.toISOString(),
      source: weatherResult.sources,
      stale: weatherResult.stale,
      bestStartTimeRange: pickBestStartTime(timeline),
      timeline,
    };
  }

  async daily(params: {
    regionCode: string;
    laundryTypeCode: LaundryTypeCode;
    dryingPlace: DryingPlace;
  }): Promise<DailyEnvelope> {
    const region = await this.regions.findByCode(params.regionCode);
    const regionRef: RegionRef = {
      id: region.id,
      nx: region.nx,
      ny: region.ny,
      sido: region.sido,
      sigungu: region.sigungu,
    };
    const weatherResult = await this.weatherQuery.getForRegion(regionRef);
    const base = await this.getBaseDryHours(params.laundryTypeCode);

    const points = weatherResult.hourly.map((h) => {
      const weather = toWeatherInput(h, weatherResult.airQuality);
      const hourOfDay = new Date(h.forecastAt).getHours();
      const score = this.calculateRaw(
        weather,
        hourOfDay,
        params.dryingPlace,
        params.laundryTypeCode,
        LaundryAmount.MEDIUM,
        base.min,
        base.max,
      );
      return {
        forecastAt: new Date(h.forecastAt),
        hourOfDay,
        overallScore: score.overallScore,
        temperatureC: h.temperatureC,
        estimatedDryHoursMin: score.estimatedDryHoursMin,
        estimatedDryHoursMax: score.estimatedDryHoursMax,
      };
    });

    return {
      region: {
        admCode: region.admCode,
        displayName: `${region.sido} ${region.sigungu} ${region.eupmyeondong}`,
        nx: region.nx,
        ny: region.ny,
      },
      generatedAt: weatherResult.generatedAt.toISOString(),
      source: weatherResult.sources,
      stale: weatherResult.stale,
      days: aggregateDaily(points),
    };
  }
}

function toWeatherInput(
  current: WeatherCurrent | WeatherHourly,
  air: AirQualitySnapshot | null,
): WeatherInput {
  return {
    temperatureC: current.temperatureC,
    humidityPercent: current.humidityPercent,
    precipType: current.precipType as PrecipType,
    precipitationProbability: current.precipitationProbability,
    windSpeedMps: current.windSpeedMps,
    skyCondition: current.skyCondition as SkyCondition,
    pm10Grade: air?.pm10Grade ?? null,
    pm25Grade: air?.pm25Grade ?? null,
  };
}

function pickBestStartTime(
  timeline: Array<{ forecastAt: string; hourOfDay: number; overallScore: number }>,
): string | null {
  if (timeline.length === 0) return null;
  let best = timeline[0];
  for (const t of timeline) {
    if (t.overallScore > best.overallScore) best = t;
  }
  if (best.overallScore < 40) return null;
  const endHour = (best.hourOfDay + 2) % 24;
  return `${String(best.hourOfDay).padStart(2, '0')}:00 ~ ${String(endHour).padStart(2, '0')}:00`;
}
