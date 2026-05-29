import { MockAirQualityProvider } from './mock-air-quality.provider';
import { pm10ToGrade, pm25ToGrade } from './types';

describe('MockAirQualityProvider', () => {
  let provider: MockAirQualityProvider;

  beforeEach(() => {
    provider = new MockAirQualityProvider();
  });

  it('미세먼지 데이터 반환', async () => {
    const snapshot = await provider.fetchByRegion({ sido: '서울' });
    expect(snapshot.pm10Value).toBeDefined();
    expect(snapshot.pm25Value).toBeDefined();
    expect(snapshot.stationName).toContain('서울');
  });
});

describe('pm10ToGrade', () => {
  it('경계값', () => {
    expect(pm10ToGrade(null)).toBeNull();
    expect(pm10ToGrade(0)).toBe(1);
    expect(pm10ToGrade(30)).toBe(1);
    expect(pm10ToGrade(31)).toBe(2);
    expect(pm10ToGrade(80)).toBe(2);
    expect(pm10ToGrade(81)).toBe(3);
    expect(pm10ToGrade(150)).toBe(3);
    expect(pm10ToGrade(151)).toBe(4);
  });
});

describe('pm25ToGrade', () => {
  it('경계값', () => {
    expect(pm25ToGrade(null)).toBeNull();
    expect(pm25ToGrade(15)).toBe(1);
    expect(pm25ToGrade(16)).toBe(2);
    expect(pm25ToGrade(35)).toBe(2);
    expect(pm25ToGrade(36)).toBe(3);
    expect(pm25ToGrade(75)).toBe(3);
    expect(pm25ToGrade(76)).toBe(4);
  });
});
