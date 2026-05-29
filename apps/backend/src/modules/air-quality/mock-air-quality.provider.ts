import { Injectable } from '@nestjs/common';
import { AirQualityProvider, AirQualitySnapshot } from './types';

@Injectable()
export class MockAirQualityProvider implements AirQualityProvider {
  public readonly name = 'MOCK_AIR';

  async fetchByRegion(input: {
    sido: string;
    sigungu?: string;
  }): Promise<AirQualitySnapshot> {
    return {
      pm10Value: 35,
      pm10Grade: 2,
      pm25Value: 18,
      pm25Grade: 2,
      stationName: `${input.sido} 평균`,
      observedAt: new Date(),
    };
  }
}
