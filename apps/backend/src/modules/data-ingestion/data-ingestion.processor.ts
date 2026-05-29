import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import {
  DATA_INGESTION_QUEUE,
  INGEST_JOB,
  IngestAirQualityPayload,
  IngestWeatherPayload,
} from './data-ingestion.constants';
import { DataIngestionService } from './data-ingestion.service';
import { DataIngestionScheduler } from './data-ingestion.scheduler';

@Processor(DATA_INGESTION_QUEUE)
export class DataIngestionProcessor extends WorkerHost {
  private readonly logger = new Logger(DataIngestionProcessor.name);

  constructor(
    private readonly service: DataIngestionService,
    private readonly scheduler: DataIngestionScheduler,
  ) {
    super();
  }

  async process(job: Job): Promise<unknown> {
    try {
      switch (job.name) {
        case INGEST_JOB.WEATHER_CURRENT:
        case INGEST_JOB.WEATHER_FORECAST:
          return await this.service.ingestWeather(
            job.data as IngestWeatherPayload,
          );
        case INGEST_JOB.AIR_QUALITY:
          return await this.service.ingestAirQuality(
            job.data as IngestAirQualityPayload,
          );
        case INGEST_JOB.WEATHER_FANOUT: {
          const count = await this.scheduler.enqueueWeatherForAllRegions();
          this.logger.log(`weather fanout: enqueued ${count} regions`);
          return { enqueued: count };
        }
        case INGEST_JOB.AIR_QUALITY_FANOUT: {
          const count = await this.scheduler.enqueueAirQualityForAllRegions();
          this.logger.log(`air-quality fanout: enqueued ${count} regions`);
          return { enqueued: count };
        }
        default:
          this.logger.warn(`Unknown job: ${job.name}`);
          return null;
      }
    } catch (e) {
      this.logger.error(
        `Job ${job.name} (id=${job.id}) failed: ${(e as Error).message}`,
      );
      throw e;
    }
  }
}
