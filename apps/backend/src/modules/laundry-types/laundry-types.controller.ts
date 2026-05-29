import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { LaundryTypesService } from './laundry-types.service';

@ApiTags('laundry-types')
@Controller({ path: 'laundry-types', version: '1' })
export class LaundryTypesController {
  constructor(private readonly laundryTypes: LaundryTypesService) {}

  @Get()
  @ApiOperation({ summary: '빨래 종류 목록 (얇음/중간/두꺼움)' })
  findAll() {
    return this.laundryTypes.findActive();
  }
}
