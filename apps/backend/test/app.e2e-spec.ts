import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('/api/v1/version (GET)', () => {
    return request(app.getHttpServer())
      .get('/api/v1/version')
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('name', 'ppallae-backend');
        expect(res.body).toHaveProperty('version');
      });
  });
});
