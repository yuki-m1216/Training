import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  describe('/users (GET)', () => {
    it('should return all users', () => {
      return request(app.getHttpServer())
        .get('/users')
        .expect(200)
        .expect((res) => {
          expect(res.body).toBeInstanceOf(Array);
          expect(res.body.length).toBeGreaterThan(0);
        });
    });
  });

  describe('/users (POST)', () => {
    it('should create a new user', () => {
      const createUserDto = {
        name: 'E2E Test User',
        email: 'e2e@example.com',
      };

      return request(app.getHttpServer())
        .post('/users')
        .send(createUserDto)
        .expect(201)
        .expect((res) => {
          expect(res.body.name).toBe(createUserDto.name);
          expect(res.body.email).toBe(createUserDto.email);
          expect(res.body.id).toBeDefined();
        });
    });

    it('should validate required fields', () => {
      return request(app.getHttpServer()).post('/users').send({}).expect(400);
    });
  });

  describe('/users/:id (GET)', () => {
    it('should return a user by id', () => {
      return request(app.getHttpServer())
        .get(`/users/1`)
        .expect(200)
        .expect((res) => {
          expect(res.body.id).toBe(1);
          expect(res.body.name).toBeDefined();
          expect(res.body.email).toBeDefined();
        });
    });

    it('should return 404 if user not found', () => {
      return request(app.getHttpServer()).get(`/users/999`).expect(404);
    });
  });
});
