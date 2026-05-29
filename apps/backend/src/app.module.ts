import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { TerminusModule } from '@nestjs/terminus';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';
import { CacheModule } from './cache/cache.module';
import { HealthModule } from './health/health.module';
import { LaundryScoreModule } from './modules/laundry-score';
import { WeatherModule } from './modules/weather';
import { AirQualityModule } from './modules/air-quality';
import { DataIngestionModule } from './modules/data-ingestion';
import { RegionsModule } from './modules/regions/regions.module';
import { LaundryTypesModule } from './modules/laundry-types/laundry-types.module';
import { WeatherQueryModule } from './modules/weather-query/weather-query.module';
import { WidgetModule } from './modules/widget/widget.module';
import { NoticesModule } from './modules/notices/notices.module';
import { AppConfigModule } from './modules/app-config/app-config.module';
import { AdminModule } from './modules/admin/admin.module';
import { LaundromatsModule } from './modules/laundromats/laundromats.module';
import { envValidationSchema } from './config/env.validation';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
      validate: envValidationSchema,
    }),
    // 전역 rate limit: 분당 100회
    ThrottlerModule.forRoot([
      { name: 'default', ttl: 60_000, limit: 100 },
    ]),
    TerminusModule,
    PrismaModule,
    RedisModule,
    CacheModule,
    HealthModule,
    WeatherModule,
    AirQualityModule,
    DataIngestionModule,
    WeatherQueryModule,
    RegionsModule,
    LaundryTypesModule,
    LaundryScoreModule,
    WidgetModule,
    NoticesModule,
    AppConfigModule,
    AdminModule,
    LaundromatsModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
