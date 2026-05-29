import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { WidgetService } from './widget.service';

@ApiTags('widget')
@Controller({ path: 'widget', version: '1' })
export class WidgetController {
  constructor(private readonly widget: WidgetService) {}

  @Get('summary')
  @ApiOperation({ summary: '위젯용 요약 (지역/지수/한 줄 추천)' })
  @ApiQuery({ name: 'regionCode', example: '1168010100' })
  summary(@Query('regionCode') regionCode: string) {
    return this.widget.summary(regionCode);
  }
}
