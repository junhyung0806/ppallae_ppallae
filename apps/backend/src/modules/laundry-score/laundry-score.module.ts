import { Module } from '@nestjs/common';
import { LaundryScoreService } from './laundry-score.service';
import { LaundryScoreController } from './laundry-score.controller';
import { RegionsModule } from '../regions/regions.module';
import { WeatherQueryModule } from '../weather-query/weather-query.module';

@Module({
  imports: [RegionsModule, WeatherQueryModule],
  controllers: [LaundryScoreController],
  providers: [LaundryScoreService],
  exports: [LaundryScoreService],
})
export class LaundryScoreModule {}
