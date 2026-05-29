import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { KmaWeatherProvider } from './kma-weather.provider';
import { MockWeatherProvider } from './mock-weather.provider';
import { WeatherProvider } from './types';

export const WEATHER_PROVIDER = 'WEATHER_PROVIDER';

@Module({
  providers: [
    KmaWeatherProvider,
    MockWeatherProvider,
    {
      provide: WEATHER_PROVIDER,
      useFactory: (
        config: ConfigService,
        kma: KmaWeatherProvider,
        mock: MockWeatherProvider,
      ): WeatherProvider => {
        const hasKey = !!config.get<string>('KMA_API_KEY')?.trim();
        const forceMock = config.get<string>('WEATHER_PROVIDER_MOCK') === 'true';
        return forceMock || !hasKey ? mock : kma;
      },
      inject: [ConfigService, KmaWeatherProvider, MockWeatherProvider],
    },
  ],
  exports: [WEATHER_PROVIDER, KmaWeatherProvider, MockWeatherProvider],
})
export class WeatherModule {}
