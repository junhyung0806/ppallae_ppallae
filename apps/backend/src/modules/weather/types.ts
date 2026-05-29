export interface KmaGridPoint {
  nx: number;
  ny: number;
}

export interface WeatherCurrent {
  temperatureC: number;
  humidityPercent: number;
  windSpeedMps: number;
  precipType: 'NONE' | 'RAIN' | 'SNOW' | 'SLEET';
  precipitationProbability: number;
  skyCondition: 'CLEAR' | 'PARTLY_CLOUDY' | 'CLOUDY' | 'OVERCAST';
  observedAt: Date;
}

export interface WeatherHourly extends WeatherCurrent {
  forecastAt: Date;
}

export interface WeatherBundle {
  current: WeatherCurrent;
  hourly: WeatherHourly[];
  source: string;
}

export interface WeatherProvider {
  readonly name: string;
  fetchBundle(input: {
    nx: number;
    ny: number;
    latitude?: number;
    longitude?: number;
  }): Promise<WeatherBundle>;
}

export class WeatherProviderError extends Error {
  constructor(
    public readonly code: string,
    public readonly stage: string,
    message: string,
    public readonly debugMessage?: string,
  ) {
    super(message);
    this.name = 'WeatherProviderError';
  }
}
