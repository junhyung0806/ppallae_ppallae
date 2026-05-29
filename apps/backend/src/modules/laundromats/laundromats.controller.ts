import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { LaundromatsService } from './laundromats.service';
import { CoordsQueryDto } from '../../common/dto/coords.dto';

@ApiTags('laundromats')
@Controller({ path: 'laundromats', version: '1' })
export class LaundromatsController {
  constructor(private readonly laundromats: LaundromatsService) {}

  @Get('nearby')
  @ApiOperation({ summary: '내 주변 빨래방 (카카오 로컬, 키 없으면 mock)' })
  nearby(@Query() query: CoordsQueryDto) {
    return this.laundromats.nearby(query.lat, query.lng);
  }
}
