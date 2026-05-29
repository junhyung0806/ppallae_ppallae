import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AirKoreaProvider } from './airkorea.provider';
import { MockAirQualityProvider } from './mock-air-quality.provider';
import { AirQualityProvider } from './types';

export const AIR_QUALITY_PROVIDER = 'AIR_QUALITY_PROVIDER';

@Module({
  providers: [
    AirKoreaProvider,
    MockAirQualityProvider,
    {
      provide: AIR_QUALITY_PROVIDER,
      useFactory: (
        config: ConfigService,
        airkorea: AirKoreaProvider,
        mock: MockAirQualityProvider,
      ): AirQualityProvider => {
        const hasKey = !!config.get<string>('AIRKOREA_API_KEY')?.trim();
        const forceMock = config.get<string>('AIR_QUALITY_PROVIDER_MOCK') === 'true';
        return forceMock || !hasKey ? mock : airkorea;
      },
      inject: [ConfigService, AirKoreaProvider, MockAirQualityProvider],
    },
  ],
  exports: [AIR_QUALITY_PROVIDER, AirKoreaProvider, MockAirQualityProvider],
})
export class AirQualityModule {}
