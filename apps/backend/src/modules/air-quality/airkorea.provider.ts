import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  AirQualityProvider,
  AirQualityProviderError,
  AirQualitySnapshot,
  pm10ToGrade,
  pm25ToGrade,
} from './types';

interface AirKoreaItem {
  dataTime?: string;
  stationName?: string;
  pm10Value?: string;
  pm25Value?: string;
  pm10Grade?: string;
  pm25Grade?: string;
}

@Injectable()
export class AirKoreaProvider implements AirQualityProvider {
  public readonly name = 'AIRKOREA';
  private readonly apiKey: string;
  private readonly sidoUrl: string;
  private readonly timeoutMs: number;

  constructor(config: ConfigService) {
    this.apiKey = config.get<string>('AIRKOREA_API_KEY', '');
    this.sidoUrl = config.get<string>(
      'AIRKOREA_SIDO_URL',
      'http://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty',
    );
    this.timeoutMs = config.get<number>('AIRKOREA_TIMEOUT_MS', 10_000);
  }

  async fetchByRegion(input: {
    sido: string;
    sigungu?: string;
    nearestStation?: string;
  }): Promise<AirQualitySnapshot> {
    if (!this.apiKey.trim()) {
      throw new AirQualityProviderError(
        'AIRKOREA-001',
        'config_check',
        'AirKorea API key is missing.',
      );
    }

    const params = new URLSearchParams({
      serviceKey: this.apiKey,
      returnType: 'json',
      numOfRows: '100',
      pageNo: '1',
      sidoName: normalizeSidoName(input.sido),
      ver: '1.3',
    });
    const url = `${this.sidoUrl}?${params.toString()}`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    let response: Response;
    try {
      response = await fetch(url, { signal: controller.signal });
    } catch (e) {
      const err = e as Error;
      throw new AirQualityProviderError(
        'AIRKOREA-003',
        'http_request',
        'AirKorea request failed.',
        err.message,
      );
    } finally {
      clearTimeout(timeout);
    }

    if (!response.ok) {
      throw new AirQualityProviderError(
        'AIRKOREA-004',
        'http_response',
        `AirKorea returned status ${response.status}`,
      );
    }

    let body: { response?: { body?: { items?: AirKoreaItem[] } } };
    try {
      body = await response.json();
    } catch (e) {
      throw new AirQualityProviderError(
        'AIRKOREA-005',
        'response_parse',
        'Failed to parse AirKorea response.',
        (e as Error).message,
      );
    }

    const items = body.response?.body?.items ?? [];
    if (items.length === 0) {
      throw new AirQualityProviderError(
        'AIRKOREA-006',
        'no_items',
        'AirKorea response missing items.',
      );
    }

    const target =
      (input.nearestStation
        ? items.find((it) => it.stationName === input.nearestStation)
        : null) ?? items[0];

    return this.toSnapshot(target);
  }

  private toSnapshot(item: AirKoreaItem): AirQualitySnapshot {
    const pm10Value = parseNumericOrNull(item.pm10Value);
    const pm25Value = parseNumericOrNull(item.pm25Value);
    const pm10Grade =
      parseNumericOrNull(item.pm10Grade) ?? pm10ToGrade(pm10Value);
    const pm25Grade =
      parseNumericOrNull(item.pm25Grade) ?? pm25ToGrade(pm25Value);

    return {
      pm10Value,
      pm10Grade,
      pm25Value,
      pm25Grade,
      stationName: item.stationName ?? null,
      observedAt: parseAirKoreaDateTime(item.dataTime) ?? new Date(),
    };
  }
}

// 에어코리아 sidoName은 축약형만 허용 (서울특별시 → 서울)
const SIDO_MAP: Record<string, string> = {
  서울특별시: '서울',
  부산광역시: '부산',
  대구광역시: '대구',
  인천광역시: '인천',
  광주광역시: '광주',
  대전광역시: '대전',
  울산광역시: '울산',
  세종특별자치시: '세종',
  경기도: '경기',
  강원특별자치도: '강원',
  강원도: '강원',
  충청북도: '충북',
  충청남도: '충남',
  전북특별자치도: '전북',
  전라북도: '전북',
  전라남도: '전남',
  경상북도: '경북',
  경상남도: '경남',
  제주특별자치도: '제주',
};

function normalizeSidoName(sido: string): string {
  return SIDO_MAP[sido] ?? sido;
}

function parseNumericOrNull(value: string | undefined): number | null {
  if (value == null || value === '-' || value === '') return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function parseAirKoreaDateTime(value: string | undefined): Date | null {
  if (!value) return null;
  const [datePart, timePart] = value.split(' ');
  if (!datePart || !timePart) return null;
  const [year, month, day] = datePart.split('-').map(Number);
  const [hour, minute] = timePart.split(':').map(Number);
  if (![year, month, day, hour, minute].every(Number.isFinite)) return null;
  return new Date(year, month - 1, day, hour, minute);
}
