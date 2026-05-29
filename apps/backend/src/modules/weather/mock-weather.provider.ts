import { Injectable } from '@nestjs/common';
import { WeatherBundle, WeatherHourly, WeatherProvider } from './types';

@Injectable()
export class MockWeatherProvider implements WeatherProvider {
  public readonly name = 'MOCK';

  async fetchBundle(input: { nx: number; ny: number }): Promise<WeatherBundle> {
    const now = new Date();
    const hourly: WeatherHourly[] = [];

    // 7일치, 2시간 간격으로 생성 (시간별 카드 + 주간 집계용)
    const totalHours = 7 * 24;
    for (let i = 1; i <= totalHours; i += 2) {
      const forecastAt = new Date(now);
      forecastAt.setHours(forecastAt.getHours() + i, 0, 0, 0);

      const hod = forecastAt.getHours();
      const dayIndex = Math.floor(i / 24);
      // 낮에는 따뜻하고 건조, 밤에는 서늘하고 습함
      const dayWarmth = Math.sin(((hod - 6) / 24) * Math.PI * 2) * 6;
      const temp = 17 + dayWarmth - dayIndex * 0.5;
      const humidity = 55 - Math.round(dayWarmth) + (dayIndex % 3) * 5;
      // 며칠에 한 번 비
      const rainyDay = dayIndex === 2 || dayIndex === 5;
      const isRainHour = rainyDay && hod >= 9 && hod <= 18;

      hourly.push({
        temperatureC: Math.round(temp * 10) / 10,
        humidityPercent: Math.max(30, Math.min(95, humidity)),
        windSpeedMps: 2.0 + (i % 3),
        precipType: isRainHour ? 'RAIN' : 'NONE',
        precipitationProbability: rainyDay ? 70 : hod >= 6 && hod <= 18 ? 10 : 30,
        skyCondition: rainyDay
          ? 'OVERCAST'
          : hod >= 7 && hod <= 16
            ? 'CLEAR'
            : 'PARTLY_CLOUDY',
        observedAt: now,
        forecastAt,
      });
    }

    return {
      current: {
        temperatureC: 22,
        humidityPercent: 50,
        windSpeedMps: 2.5,
        precipType: 'NONE',
        precipitationProbability: 10,
        skyCondition: 'CLEAR',
        observedAt: now,
      },
      hourly,
      source: `mock:grid(${input.nx},${input.ny})`,
    };
  }
}
