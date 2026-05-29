export interface AirQualitySnapshot {
  pm10Value: number | null;
  pm10Grade: number | null;
  pm25Value: number | null;
  pm25Grade: number | null;
  stationName: string | null;
  observedAt: Date;
}

export interface AirQualityProvider {
  readonly name: string;
  fetchByRegion(input: {
    sido: string;
    sigungu?: string;
    nearestStation?: string;
  }): Promise<AirQualitySnapshot>;
}

export class AirQualityProviderError extends Error {
  constructor(
    public readonly code: string,
    public readonly stage: string,
    message: string,
    public readonly debugMessage?: string,
  ) {
    super(message);
    this.name = 'AirQualityProviderError';
  }
}

export function pm10ToGrade(value: number | null): number | null {
  if (value == null) return null;
  if (value <= 30) return 1;
  if (value <= 80) return 2;
  if (value <= 150) return 3;
  return 4;
}

export function pm25ToGrade(value: number | null): number | null {
  if (value == null) return null;
  if (value <= 15) return 1;
  if (value <= 35) return 2;
  if (value <= 75) return 3;
  return 4;
}
