import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  WeatherBundle,
  WeatherCurrent,
  WeatherHourly,
  WeatherProvider,
  WeatherProviderError,
} from './types';
import {
  formatKmaDate,
  formatKmaTime,
  latestUltraFcstBase,
  latestUltraNcstBase,
  latestVillageFcstBase,
} from './kma-base-time';

interface KmaItem {
  category?: string;
  obsrValue?: string;
  fcstValue?: string;
  fcstDate?: string;
  fcstTime?: string;
}

@Injectable()
export class KmaWeatherProvider implements WeatherProvider {
  public readonly name = 'KMA';
  private readonly logger = new Logger(KmaWeatherProvider.name);
  private readonly authKey: string;
  private readonly ultraNcstUrl: string;
  private readonly ultraFcstUrl: string;
  private readonly villageFcstUrl: string;
  private readonly timeoutMs: number;

  constructor(config: ConfigService) {
    this.authKey = config.get<string>('KMA_API_KEY', '');
    this.ultraNcstUrl = config.get<string>(
      'KMA_ULTRA_NCST_URL',
      'https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getUltraSrtNcst',
    );
    this.ultraFcstUrl = config.get<string>(
      'KMA_ULTRA_FCST_URL',
      'https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getUltraSrtFcst',
    );
    this.villageFcstUrl = config.get<string>(
      'KMA_VILLAGE_FCST_URL',
      'https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getVilageFcst',
    );
    this.timeoutMs = config.get<number>('KMA_TIMEOUT_MS', 10_000);
  }

  async fetchBundle(input: { nx: number; ny: number }): Promise<WeatherBundle> {
    if (!this.authKey.trim()) {
      throw new WeatherProviderError(
        'KMA-001',
        'config_check',
        'KMA API key is missing.',
      );
    }

    const now = new Date();
    const ncstBase = latestUltraNcstBase(now);
    const ultraBase = latestUltraFcstBase(now);

    const currentItems = await this.fetchItems('ultra_ncst', this.ultraNcstUrl, {
      pageNo: '1',
      numOfRows: '100',
      dataType: 'JSON',
      base_date: formatKmaDate(ncstBase),
      base_time: formatKmaTime(ncstBase),
      nx: String(input.nx),
      ny: String(input.ny),
      authKey: this.authKey,
    });

    // 초단기예보(6시간, 1시간 간격, 정확) + 동네예보(3일, 3시간 간격) 병합
    const sources: string[] = [];

    let ultraHourly: WeatherHourly[] = [];
    try {
      const ultraItems = await this.fetchItems('ultra_fcst', this.ultraFcstUrl, {
        pageNo: '1',
        numOfRows: '120',
        dataType: 'JSON',
        base_date: formatKmaDate(ultraBase),
        base_time: formatKmaTime(ultraBase),
        nx: String(input.nx),
        ny: String(input.ny),
        authKey: this.authKey,
      });
      ultraHourly = this.buildHourlyForecasts(ultraItems, now, 'kma_ultra_fcst');
      if (ultraHourly.length > 0) sources.push('kma_ultra_fcst');
    } catch (e) {
      this.logger.warn(`ultra_fcst failed: ${(e as Error).message}`);
    }

    let villageHourly: WeatherHourly[] = [];
    try {
      const villageBase = latestVillageFcstBase(now);
      const villageItems = await this.fetchItems(
        'village_fcst',
        this.villageFcstUrl,
        {
          pageNo: '1',
          numOfRows: '800',
          dataType: 'JSON',
          base_date: formatKmaDate(villageBase),
          base_time: formatKmaTime(villageBase),
          nx: String(input.nx),
          ny: String(input.ny),
          authKey: this.authKey,
        },
      );
      villageHourly = this.buildHourlyForecasts(
        villageItems,
        now,
        'kma_village_fcst',
      );
      if (villageHourly.length > 0) sources.push('kma_village_fcst');
    } catch (e) {
      this.logger.warn(`village_fcst failed: ${(e as Error).message}`);
    }

    const hourly = mergeForecasts(ultraHourly, villageHourly);
    if (hourly.length === 0) {
      throw new WeatherProviderError(
        'KMA-006',
        'forecast_categories',
        'No usable forecast categories in KMA response.',
      );
    }

    const current = this.buildCurrentSnapshot(currentItems, hourly[0]);

    // 3일치(최대 72시간) 정도까지만
    return { current, hourly: hourly.slice(0, 72), source: sources.join('+') };
  }

  private async fetchItems(
    requestName: string,
    url: string,
    query: Record<string, string>,
  ): Promise<KmaItem[]> {
    const searchParams = new URLSearchParams(query).toString();
    const fullUrl = `${url}?${searchParams}`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    let response: Response;
    try {
      response = await fetch(fullUrl, { signal: controller.signal });
    } catch (e) {
      const err = e as Error;
      const code = err.name === 'AbortError' ? 'KMA-003' : 'KMA-003';
      throw new WeatherProviderError(
        code,
        `${requestName}_http_request`,
        'KMA request failed.',
        err.message,
      );
    } finally {
      clearTimeout(timeout);
    }

    if (!response.ok) {
      throw new WeatherProviderError(
        'KMA-004',
        `${requestName}_http_response`,
        'KMA returned non-200 status.',
        `HTTP ${response.status}`,
      );
    }

    let decoded: { response?: { header?: { resultCode?: string; resultMsg?: string }; body?: { items?: { item?: unknown } } } };
    try {
      decoded = await response.json();
    } catch (e) {
      throw new WeatherProviderError(
        'KMA-005',
        `${requestName}_response_parse`,
        'Failed to parse KMA response.',
        (e as Error).message,
      );
    }

    const header = decoded.response?.header;
    const resultCode = String(header?.resultCode ?? '');
    const resultMsg = String(header?.resultMsg ?? '');
    if (resultCode && resultCode !== '00') {
      const isAuth = this.looksLikeAuthFailure(resultCode, resultMsg);
      throw new WeatherProviderError(
        isAuth ? 'KMA-010' : 'KMA-005',
        `${requestName}_response_header`,
        'KMA returned error response.',
        resultMsg,
      );
    }

    const items = decoded.response?.body?.items?.item;
    if (Array.isArray(items)) {
      return items.filter((i): i is KmaItem => typeof i === 'object' && i !== null);
    }
    if (items && typeof items === 'object') {
      return [items as KmaItem];
    }
    throw new WeatherProviderError(
      'KMA-006',
      'response_items_missing',
      'KMA response missing items.',
    );
  }

  private buildCurrentSnapshot(
    currentItems: KmaItem[],
    firstHourly: WeatherHourly,
  ): WeatherCurrent {
    const values: Record<string, string> = {};
    for (const item of currentItems) {
      const category = String(item.category ?? '');
      const obsrValue = String(item.obsrValue ?? '');
      if (category) values[category] = obsrValue;
    }

    return {
      temperatureC: parseFloatOrDefault(values['T1H'], firstHourly.temperatureC),
      humidityPercent: parseIntOrDefault(values['REH'], firstHourly.humidityPercent),
      windSpeedMps: parseFloatOrDefault(values['WSD'], firstHourly.windSpeedMps),
      precipType: mapPrecipType(values['PTY']),
      precipitationProbability: firstHourly.precipitationProbability,
      skyCondition: mapSkyCondition(values['SKY'], values['PTY']),
      observedAt: new Date(),
    };
  }

  private buildHourlyForecasts(
    items: KmaItem[],
    now: Date,
    source: string,
  ): WeatherHourly[] {
    const grouped: Map<string, Record<string, string>> = new Map();
    for (const item of items) {
      const fcstDate = String(item.fcstDate ?? '');
      const fcstTime = String(item.fcstTime ?? '');
      const category = String(item.category ?? '');
      const fcstValue = String(item.fcstValue ?? '');
      if (!fcstDate || !fcstTime || !category) continue;
      const key = `${fcstDate}${fcstTime}`;
      const bucket = grouped.get(key) ?? {};
      bucket[category] = fcstValue;
      grouped.set(key, bucket);
    }

    const results: WeatherHourly[] = [];
    const sortedKeys = Array.from(grouped.keys()).sort();
    for (const key of sortedKeys) {
      const forecastAt = parseForecastDateTime(key);
      if (!forecastAt || forecastAt < now) continue;
      const v = grouped.get(key)!;
      if (!hasRequiredCategories(v)) continue;
      const tempStr = source === 'kma_village_fcst' ? v['TMP'] ?? v['T1H'] : v['T1H'] ?? v['TMP'];
      const precipType = mapPrecipType(v['PTY']);
      // POP은 초단기예보에 없음 → 누락 시 강수형태로 보정
      const pop =
        'POP' in v
          ? parseIntOrDefault(v['POP'], 0)
          : precipType === 'NONE'
            ? 10
            : 80;
      results.push({
        temperatureC: parseFloatOrDefault(tempStr, 20.0),
        humidityPercent: parseIntOrDefault(v['REH'], 55),
        windSpeedMps: parseFloatOrDefault(v['WSD'], 1.5),
        precipType,
        precipitationProbability: pop,
        skyCondition: mapSkyCondition(v['SKY'], v['PTY']),
        observedAt: now,
        forecastAt,
      });
    }
    return results;
  }

  private looksLikeAuthFailure(resultCode: string, resultMsg: string): boolean {
    const normalized = resultMsg.toLowerCase();
    return (
      resultCode === '30' ||
      normalized.includes('servicekey') ||
      normalized.includes('auth') ||
      normalized.includes('key') ||
      normalized.includes('unauthorized') ||
      normalized.includes('forbidden')
    );
  }
}

// 초단기예보(정확, 가까운 시간)를 우선하고, 그 외 시간은 동네예보로 채움
function mergeForecasts(
  ultra: WeatherHourly[],
  village: WeatherHourly[],
): WeatherHourly[] {
  const byTime = new Map<number, WeatherHourly>();
  // 동네예보 먼저 깔고
  for (const v of village) byTime.set(v.forecastAt.getTime(), v);
  // 초단기예보로 덮어쓰기 (겹치는 시간은 초단기 우선)
  for (const u of ultra) byTime.set(u.forecastAt.getTime(), u);

  return Array.from(byTime.values()).sort(
    (a, b) => a.forecastAt.getTime() - b.forecastAt.getTime(),
  );
}

function parseFloatOrDefault(value: string | undefined, fallback: number): number {
  if (value == null) return fallback;
  const n = Number.parseFloat(value);
  return Number.isFinite(n) ? n : fallback;
}

function parseIntOrDefault(value: string | undefined, fallback: number): number {
  if (value == null) return fallback;
  const n = Number.parseInt(value, 10);
  return Number.isFinite(n) ? n : fallback;
}

function mapPrecipType(pty: string | undefined): WeatherCurrent['precipType'] {
  switch (pty) {
    case '1':
    case '4':
    case '5':
      return 'RAIN';
    case '2':
    case '6':
      return 'SLEET';
    case '3':
    case '7':
      return 'SNOW';
    default:
      return 'NONE';
  }
}

function mapSkyCondition(
  sky: string | undefined,
  pty: string | undefined,
): WeatherCurrent['skyCondition'] {
  if (pty && pty !== '0') return 'OVERCAST';
  switch (sky) {
    case '1':
      return 'CLEAR';
    case '3':
      return 'PARTLY_CLOUDY';
    case '4':
      return 'OVERCAST';
    default:
      return 'PARTLY_CLOUDY';
  }
}

function hasRequiredCategories(v: Record<string, string>): boolean {
  // POP(강수확률)은 동네예보에만 있고 초단기예보에는 없으므로 필수에서 제외.
  // 누락 시 기본값/PTY로 보정한다.
  return (
    ('T1H' in v || 'TMP' in v) &&
    'REH' in v &&
    'WSD' in v &&
    'PTY' in v &&
    'SKY' in v
  );
}

function parseForecastDateTime(key: string): Date | null {
  if (key.length !== 12) return null;
  const year = Number(key.slice(0, 4));
  const month = Number(key.slice(4, 6));
  const day = Number(key.slice(6, 8));
  const hour = Number(key.slice(8, 10));
  const minute = Number(key.slice(10, 12));
  if (![year, month, day, hour, minute].every(Number.isFinite)) return null;
  return new Date(year, month - 1, day, hour, minute);
}
