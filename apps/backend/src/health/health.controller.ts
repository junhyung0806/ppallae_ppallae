import { Controller, Get, Version } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import {
  HealthCheck,
  HealthCheckService,
} from '@nestjs/terminus';
import { PrismaHealthIndicator } from './prisma.health';
import { RedisHealthIndicator } from './redis.health';

@ApiTags('health')
@Controller()
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly prismaHealth: PrismaHealthIndicator,
    private readonly redisHealth: RedisHealthIndicator,
  ) {}

  @Get('health')
  @Version('1')
  @HealthCheck()
  @ApiOperation({ summary: '서버 상태 확인' })
  check() {
    return this.health.check([
      () => this.prismaHealth.isHealthy('database'),
      () => this.redisHealth.isHealthy('redis'),
    ]);
  }

  @Get('version')
  @Version('1')
  @ApiOperation({ summary: '서버 버전 정보' })
  version() {
    return {
      name: 'ppallae-backend',
      version: process.env['npm_package_version'] ?? '0.1.0',
      environment: process.env['NODE_ENV'] ?? 'development',
    };
  }
}
