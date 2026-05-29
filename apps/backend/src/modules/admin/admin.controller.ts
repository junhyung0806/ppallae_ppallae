import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { AdminAuthGuard, AdminRequest } from './auth/admin-auth.guard';
import { ConfigDto, LaundryTypeUpdateDto, NoticeDto } from './dto/admin.dto';

@ApiTags('admin')
@ApiBearerAuth()
@UseGuards(AdminAuthGuard)
@Controller({ path: 'admin', version: '1' })
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('dashboard')
  @ApiOperation({ summary: '대시보드 통계' })
  dashboard() {
    return this.admin.dashboard();
  }

  // ── 빨래 종류 ──

  @Get('laundry-types')
  @ApiOperation({ summary: '빨래 종류 목록 (관리)' })
  listLaundryTypes() {
    return this.admin.listLaundryTypes();
  }

  @Put('laundry-types/:code')
  @ApiOperation({ summary: '빨래 종류 수정 (건조시간/문구 등)' })
  async updateLaundryType(
    @Param('code') code: string,
    @Body() dto: LaundryTypeUpdateDto,
    @Req() req: AdminRequest,
  ) {
    const result = await this.admin.updateLaundryType(code, dto);
    await this.admin.writeAuditLog(
      req.admin!.sub,
      'laundry-type.update',
      code,
      dto as Record<string, unknown>,
      req.ip,
    );
    return result;
  }

  // ── 공지 ──

  @Get('notices')
  @ApiOperation({ summary: '공지 목록 (관리)' })
  listNotices() {
    return this.admin.listNotices();
  }

  @Post('notices')
  @ApiOperation({ summary: '공지 생성' })
  async createNotice(@Body() dto: NoticeDto, @Req() req: AdminRequest) {
    const result = await this.admin.createNotice(dto);
    await this.admin.writeAuditLog(
      req.admin!.sub,
      'notice.create',
      result.id,
      { title: dto.title },
      req.ip,
    );
    return result;
  }

  @Put('notices/:id')
  @ApiOperation({ summary: '공지 수정' })
  async updateNotice(
    @Param('id') id: string,
    @Body() dto: NoticeDto,
    @Req() req: AdminRequest,
  ) {
    const result = await this.admin.updateNotice(id, dto);
    await this.admin.writeAuditLog(
      req.admin!.sub,
      'notice.update',
      id,
      { title: dto.title },
      req.ip,
    );
    return result;
  }

  @Delete('notices/:id')
  @ApiOperation({ summary: '공지 삭제' })
  async deleteNotice(@Param('id') id: string, @Req() req: AdminRequest) {
    const result = await this.admin.deleteNotice(id);
    await this.admin.writeAuditLog(req.admin!.sub, 'notice.delete', id, undefined, req.ip);
    return result;
  }

  // ── 앱 설정 ──

  @Get('configs')
  @ApiOperation({ summary: '앱 설정 목록' })
  listConfigs() {
    return this.admin.listConfigs();
  }

  @Put('configs')
  @ApiOperation({ summary: '앱 설정 추가/수정' })
  async upsertConfig(@Body() dto: ConfigDto, @Req() req: AdminRequest) {
    const result = await this.admin.upsertConfig(
      dto.key,
      dto.value,
      dto.isPublic ?? false,
    );
    await this.admin.writeAuditLog(
      req.admin!.sub,
      'config.upsert',
      dto.key,
      { value: dto.value },
      req.ip,
    );
    return result;
  }

  // ── 감사 로그 ──

  @Get('audit-logs')
  @ApiOperation({ summary: '감사 로그' })
  auditLogs(@Query('limit') limit?: string) {
    return this.admin.listAuditLogs(limit ? Number(limit) : 50);
  }
}
