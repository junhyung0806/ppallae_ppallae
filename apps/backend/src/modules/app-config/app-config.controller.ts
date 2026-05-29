import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AppConfigService } from './app-config.service';

@ApiTags('app-config')
@Controller({ path: 'app-config', version: '1' })
export class AppConfigController {
  constructor(private readonly config: AppConfigService) {}

  @Get('public')
  @ApiOperation({ summary: '공개 앱 설정 (key-value)' })
  getPublic() {
    return this.config.getPublicConfig();
  }
}
