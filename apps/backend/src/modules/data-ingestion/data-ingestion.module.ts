import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WeatherModule } from '../weather/weather.module';
import { AirQualityModule } from '../air-quality/air-quality.module';
import { DataIngestionService } from './data-ingestion.service';
import { DataIngestionProcessor } from './data-ingestion.processor';
import { DataIngestionScheduler } from './data-ingestion.scheduler';
import { DATA_INGESTION_QUEUE } from './data-ingestion.constants';

@Module({
  imports: [
    BullModule.forRootAsync({
      useFactory: (config: ConfigService) => {
        const url = new URL(config.getOrThrow<string>('REDIS_URL'));
        return {
          connection: {
            host: url.hostname,
            port: Number(url.port || 6379),
            password: url.password || undefined,
          },
        };
      },
      inject: [ConfigService],
    }),
    BullModule.registerQueue({ name: DATA_INGESTION_QUEUE }),
    WeatherModule,
    AirQualityModule,
  ],
  providers: [
    DataIngestionService,
    DataIngestionProcessor,
    DataIngestionScheduler,
  ],
  exports: [DataIngestionService, DataIngestionScheduler],
})
export class DataIngestionModule {}
