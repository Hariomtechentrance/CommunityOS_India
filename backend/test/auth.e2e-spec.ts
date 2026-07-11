import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('Auth (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('logs in via OTP request -> verify and returns a JWT', async () => {
    const phone = `+9198${Math.floor(10000000 + Math.random() * 89999999)}`;

    const requestRes = await request(app.getHttpServer())
      .post('/auth/otp/request')
      .send({ phone })
      .expect(201);

    expect(requestRes.body.devCode).toBeDefined();

    const verifyRes = await request(app.getHttpServer())
      .post('/auth/otp/verify')
      .send({ phone, code: requestRes.body.devCode })
      .expect(201);

    expect(verifyRes.body.accessToken).toBeDefined();
    expect(verifyRes.body.user.phone).toBe(phone);
  });

  it('rejects an invalid OTP code', async () => {
    const phone = `+9198${Math.floor(10000000 + Math.random() * 89999999)}`;

    await request(app.getHttpServer()).post('/auth/otp/request').send({ phone }).expect(201);

    await request(app.getHttpServer())
      .post('/auth/otp/verify')
      .send({ phone, code: '000000' })
      .expect(400);
  });
});
