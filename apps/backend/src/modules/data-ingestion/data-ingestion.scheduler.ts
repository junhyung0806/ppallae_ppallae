import { InjectQueue } from '@nestjs/bullmq';
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Queue } from 'bullmq';
import { PrismaService } from '../../prisma/prisma.service';
import {
  DATA_INGESTION_QUEUE,
  INGEST_JOB,
} from './data-ingestion.constants';

@Injectable()
export class DataIngestionScheduler implements OnModuleInit {
  private readonly logger = new Logger(DataIngestionScheduler.name);

  constructor(
    private readonly prisma: PrismaService,
    @InjectQueue(DATA_INGESTION_QUEUE) private readonly queue: Queue,
  ) {}

  async onModuleInit() {
    if (process.env.NODE_ENV === 'test') return;

    // 이전 버전의 잘못된 스케줄러 정리
    for (const old of ['weather-current-30min', 'air-quality-60min']) {
      await this.queue.removeJobScheduler(old).catch(() => undefined);
    }

    await this.queue.upsertJobScheduler(
      'weather-fanout-30min',
      { pattern: '*/30 * * * *' },
      { name: INGEST_JOB.WEATHER_FANOUT, data: {} },
    );

    await this.queue.upsertJobScheduler(
      'air-quality-fanout-60min',
      { pattern: '0 * * * *' },
      { name: INGEST_JOB.AIR_QUALITY_FANOUT, data: {} },
    );

    this.logger.log('Data ingestion schedulers registered');
  }

  async enqueueWeatherForAllRegions(): Promise<number> {
    const regions = await this.prisma.region.findMany({
      select: { id: true, nx: true, ny: true },
    });
    for (const r of regions) {
      await this.queue.add(INGEST_JOB.WEATHER_CURRENT, {
        regionId: r.id,
        nx: r.nx,
        ny: r.ny,
      });
    }
    return regions.length;
  }

  async enqueueAirQualityForAllRegions(): Promise<number> {
    const regions = await this.prisma.region.findMany({
      select: { id: true, sido: true, sigungu: true },
    });
    for (const r of regions) {
      await this.queue.add(INGEST_JOB.AIR_QUALITY, {
        regionId: r.id,
        sido: r.sido,
        sigungu: r.sigungu,
      });
    }
    return regions.length;
  }
}
