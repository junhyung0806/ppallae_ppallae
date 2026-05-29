import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { NoticesService } from './notices.service';

@ApiTags('notices')
@Controller({ path: 'notices', version: '1' })
export class NoticesController {
  constructor(private readonly notices: NoticesService) {}

  @Get('active')
  @ApiOperation({ summary: '활성 공지 목록' })
  active() {
    return this.notices.findActive();
  }
}
