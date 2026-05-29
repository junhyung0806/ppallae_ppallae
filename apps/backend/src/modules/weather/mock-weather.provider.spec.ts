import { MockWeatherProvider } from './mock-weather.provider';

describe('MockWeatherProvider', () => {
  let provider: MockWeatherProvider;

  beforeEach(() => {
    provider = new MockWeatherProvider();
  });

  it('현재 + 시간별 예보 반환 (여러 날)', async () => {
    const bundle = await provider.fetchBundle({ nx: 60, ny: 127 });
    expect(bundle.current).toBeDefined();
    expect(bundle.hourly.length).toBeGreaterThanOrEqual(24);
    expect(bundle.source).toContain('mock');
  });

  it('7일 범위의 예보를 포함', async () => {
    const bundle = await provider.fetchBundle({ nx: 60, ny: 127 });
    const days = new Set(
      bundle.hourly.map((h) => h.forecastAt.toISOString().slice(0, 10)),
    );
    expect(days.size).toBeGreaterThanOrEqual(5);
  });

  it('hourly forecastAt이 시간순 정렬', async () => {
    const bundle = await provider.fetchBundle({ nx: 60, ny: 127 });
    for (let i = 1; i < bundle.hourly.length; i++) {
      expect(bundle.hourly[i].forecastAt.getTime()).toBeGreaterThan(
        bundle.hourly[i - 1].forecastAt.getTime(),
      );
    }
  });

  it('hourly 데이터에 필수 필드 모두 포함', async () => {
    const bundle = await provider.fetchBundle({ nx: 60, ny: 127 });
    for (const h of bundle.hourly) {
      expect(typeof h.temperatureC).toBe('number');
      expect(typeof h.humidityPercent).toBe('number');
      expect(typeof h.windSpeedMps).toBe('number');
      expect(['NONE', 'RAIN', 'SNOW', 'SLEET']).toContain(h.precipType);
      expect(['CLEAR', 'PARTLY_CLOUDY', 'CLOUDY', 'OVERCAST']).toContain(
        h.skyCondition,
      );
    }
  });
});
