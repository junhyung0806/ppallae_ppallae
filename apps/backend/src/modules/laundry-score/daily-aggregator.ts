import { LaundryGrade } from './types';
import { scoreToGrade } from './score-calculator';

export interface HourlyScorePoint {
  forecastAt: Date;
  hourOfDay: number;
  overallScore: number;
  temperatureC: number;
  estimatedDryHoursMin: number;
  estimatedDryHoursMax: number;
}

export interface DailySummary {
  date: string; // YYYY-MM-DD
  weekday: number; // 0=일 ~ 6=토
  representativeScore: number;
  grade: LaundryGrade;
  minTempC: number;
  maxTempC: number;
  estimatedDryHoursMin: number;
  estimatedDryHoursMax: number;
  bestHourRange: string | null;
}

// 낮 시간(9~18시)을 가중해 하루 대표 점수를 산출
export function aggregateDaily(points: HourlyScorePoint[]): DailySummary[] {
  const byDate = new Map<string, HourlyScorePoint[]>();
  for (const p of points) {
    const date = toDateKey(p.forecastAt);
    const bucket = byDate.get(date) ?? [];
    bucket.push(p);
    byDate.set(date, bucket);
  }

  const summaries: DailySummary[] = [];
  for (const date of Array.from(byDate.keys()).sort()) {
    const dayPoints = byDate.get(date)!;
    const daytime = dayPoints.filter((p) => p.hourOfDay >= 9 && p.hourOfDay <= 18);
    const scoreSource = daytime.length > 0 ? daytime : dayPoints;

    const avgScore = Math.round(
      scoreSource.reduce((s, p) => s + p.overallScore, 0) / scoreSource.length,
    );
    const temps = dayPoints.map((p) => p.temperatureC);
    const minTemp = Math.min(...temps);
    const maxTemp = Math.max(...temps);

    // 대표 건조시간: 점수가 가장 높은 시점 기준
    const best = scoreSource.reduce((a, b) =>
      b.overallScore > a.overallScore ? b : a,
    );

    summaries.push({
      date,
      weekday: parseLocalDate(date).getDay(),
      representativeScore: avgScore,
      grade: scoreToGrade(avgScore),
      minTempC: Math.round(minTemp * 10) / 10,
      maxTempC: Math.round(maxTemp * 10) / 10,
      estimatedDryHoursMin: best.estimatedDryHoursMin,
      estimatedDryHoursMax: best.estimatedDryHoursMax,
      bestHourRange: avgScore >= 40 ? bestRange(best.hourOfDay) : null,
    });
  }

  return summaries;
}

function bestRange(hour: number): string {
  const end = (hour + 2) % 24;
  return `${pad(hour)}:00 ~ ${pad(end)}:00`;
}

function pad(n: number): string {
  return String(n).padStart(2, '0');
}

function toDateKey(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function parseLocalDate(key: string): Date {
  const [y, m, d] = key.split('-').map(Number);
  return new Date(y, m - 1, d);
}
