import { aggregateDaily, HourlyScorePoint } from './daily-aggregator';
import { LaundryGrade } from './types';

function point(
  iso: string,
  overallScore: number,
  temperatureC: number,
): HourlyScorePoint {
  const forecastAt = new Date(iso);
  return {
    forecastAt,
    hourOfDay: forecastAt.getHours(),
    overallScore,
    temperatureC,
    estimatedDryHoursMin: 2,
    estimatedDryHoursMax: 4,
  };
}

describe('aggregateDaily', () => {
  it('날짜별로 그룹화한다', () => {
    const points = [
      point('2026-05-28T10:00:00', 80, 20),
      point('2026-05-28T14:00:00', 90, 24),
      point('2026-05-29T10:00:00', 50, 15),
    ];
    const days = aggregateDaily(points);
    expect(days).toHaveLength(2);
    expect(days[0].date).toBe('2026-05-28');
    expect(days[1].date).toBe('2026-05-29');
  });

  it('낮 시간(9~18시) 점수로 대표값을 계산한다', () => {
    const points = [
      point('2026-05-28T03:00:00', 10, 12), // 밤 - 제외
      point('2026-05-28T12:00:00', 80, 22),
      point('2026-05-28T15:00:00', 90, 24),
    ];
    const days = aggregateDaily(points);
    expect(days[0].representativeScore).toBe(85); // (80+90)/2
  });

  it('최저/최고 기온은 하루 전체에서 계산', () => {
    const points = [
      point('2026-05-28T03:00:00', 10, 8),
      point('2026-05-28T12:00:00', 80, 25),
    ];
    const days = aggregateDaily(points);
    expect(days[0].minTempC).toBe(8);
    expect(days[0].maxTempC).toBe(25);
  });

  it('점수가 낮으면 추천 시간대 없음', () => {
    const points = [
      point('2026-05-28T10:00:00', 20, 12),
      point('2026-05-28T14:00:00', 25, 13),
    ];
    const days = aggregateDaily(points);
    expect(days[0].bestHourRange).toBeNull();
    expect(days[0].grade).toBe(LaundryGrade.BAD);
  });

  it('점수가 충분하면 추천 시간대 제공', () => {
    const points = [
      point('2026-05-28T10:00:00', 70, 20),
      point('2026-05-28T14:00:00', 85, 24),
    ];
    const days = aggregateDaily(points);
    expect(days[0].bestHourRange).toBe('14:00 ~ 16:00');
  });

  it('낮 데이터가 없으면 전체 데이터로 대체', () => {
    const points = [
      point('2026-05-28T03:00:00', 40, 10),
      point('2026-05-28T23:00:00', 50, 12),
    ];
    const days = aggregateDaily(points);
    expect(days[0].representativeScore).toBe(45);
  });
});
