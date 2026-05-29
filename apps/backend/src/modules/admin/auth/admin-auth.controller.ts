import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ApiProperty } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { IsEmail, IsString, MinLength } from 'class-validator';
import { AdminAuthService } from './admin-auth.service';
import { AdminAuthGuard, AdminRequest } from './admin-auth.guard';

class LoginDto {
  @ApiProperty({ example: 'admin@ppallae.dev' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'admin1234' })
  @IsString()
  @MinLength(6)
  password!: string;
}

@ApiTags('admin-auth')
@Controller({ path: 'admin/auth', version: '1' })
export class AdminAuthController {
  constructor(private readonly auth: AdminAuthService) {}

  @Post('login')
  @Throttle({ default: { ttl: 60_000, limit: 5 } }) // 무차별 대입 방지: 분당 5회
  @ApiOperation({ summary: '관리자 로그인' })
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto.email, dto.password);
  }

  @Get('me')
  @UseGuards(AdminAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '현재 관리자 정보' })
  me(@Req() req: AdminRequest) {
    return req.admin;
  }
}
