import { Module } from '@nestjs/common';
import { LaundromatsController } from './laundromats.controller';
import { LaundromatsService } from './laundromats.service';

@Module({
  controllers: [LaundromatsController],
  providers: [LaundromatsService],
})
export class LaundromatsModule {}
