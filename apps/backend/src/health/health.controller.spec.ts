import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { TerminusModule } from '@nestjs/terminus';
import { PrismaHealthIndicator } from './prisma.health';
import { RedisHealthIndicator } from './redis.health';

describe('HealthController', () => {
  let controller: HealthController;

  const mockPrismaHealth = {
    isHealthy: jest.fn().mockResolvedValue({ database: { status: 'up' } }),
  };

  const mockRedisHealth = {
    isHealthy: jest.fn().mockResolvedValue({ redis: { status: 'up' } }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [TerminusModule],
      controllers: [HealthController],
      providers: [
        { provide: PrismaHealthIndicator, useValue: mockPrismaHealth },
        { provide: RedisHealthIndicator, useValue: mockRedisHealth },
      ],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('version should return app info', () => {
    const result = controller.version();
    expect(result).toHaveProperty('name', 'ppallae-backend');
    expect(result).toHaveProperty('version');
  });
});
