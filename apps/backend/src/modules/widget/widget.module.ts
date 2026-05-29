import { Module } from '@nestjs/common';
import { LaundryScoreModule } from '../laundry-score/laundry-score.module';
import { WidgetController } from './widget.controller';
import { WidgetService } from './widget.service';

@Module({
  imports: [LaundryScoreModule],
  controllers: [WidgetController],
  providers: [WidgetService],
})
export class WidgetModule {}
