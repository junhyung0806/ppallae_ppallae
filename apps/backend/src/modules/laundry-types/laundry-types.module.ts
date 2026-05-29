import { Module } from '@nestjs/common';
import { LaundryTypesController } from './laundry-types.controller';
import { LaundryTypesService } from './laundry-types.service';

@Module({
  controllers: [LaundryTypesController],
  providers: [LaundryTypesService],
  exports: [LaundryTypesService],
})
export class LaundryTypesModule {}
