import {
  formatKmaDate,
  formatKmaTime,
  latestUltraNcstBase,
  latestUltraFcstBase,
  latestVillageFcstBase,
} from './kma-base-time';

describe('formatKmaDate/Time', () => {
  it('YYYYMMDD / HHMM 형식', () => {
    const d = new Date(2026, 4, 28, 14, 30); // May 28, 14:30
    expect(formatKmaDate(d)).toBe('20260528');
    expect(formatKmaTime(d)).toBe('1430');
  });
});

describe('latestUltraNcstBase', () => {
  it('45분 이전이면 이전 시각 정각', () => {
    const now = new Date(2026, 4, 28, 14, 30);
    const base = latestUltraNcstBase(now);
    expect(base.getHours()).toBe(13);
    expect(base.getMinutes()).toBe(0);
  });

  it('45분 이후면 현재 시각 정각', () => {
    const now = new Date(2026, 4, 28, 14, 50);
    const base = latestUltraNcstBase(now);
    expect(base.getHours()).toBe(14);
    expect(base.getMinutes()).toBe(0);
  });
});

describe('latestUltraFcstBase', () => {
  it('45분 이전이면 이전 시각 30분', () => {
    const now = new Date(2026, 4, 28, 14, 30);
    const base = latestUltraFcstBase(now);
    expect(base.getHours()).toBe(13);
    expect(base.getMinutes()).toBe(30);
  });
});

describe('latestVillageFcstBase', () => {
  it('정각 시간이 23,20,17,14,11,8,5,2 중 하나', () => {
    const now = new Date(2026, 4, 28, 15, 30);
    const base = latestVillageFcstBase(now);
    expect([23, 20, 17, 14, 11, 8, 5, 2]).toContain(base.getHours());
    expect(base.getMinutes()).toBe(0);
  });

  it('새벽 1시면 전날 23시 반환', () => {
    const now = new Date(2026, 4, 28, 1, 30);
    const base = latestVillageFcstBase(now);
    expect(base.getHours()).toBe(23);
    expect(base.getDate()).toBe(27);
  });
});
