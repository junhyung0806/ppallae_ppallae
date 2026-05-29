import { Module } from '@nestjs/common';
import { DataIngestionModule } from '../data-ingestion/data-ingestion.module';
import { WeatherQueryService } from './weather-query.service';

@Module({
  imports: [DataIngestionModule],
  providers: [WeatherQueryService],
  exports: [WeatherQueryService],
})
export class WeatherQueryModule {}
