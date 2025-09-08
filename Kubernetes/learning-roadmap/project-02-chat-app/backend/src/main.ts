import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { createRedisIoAdapter } from './common/adapters/redis-io.adapter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  app.enableCors({
    origin: process.env.FRONTEND_URL || true,
    credentials: true,
  });

  if (
    process.env.NODE_ENV === 'production' ||
    process.env.USE_REDIS === 'true'
  ) {
    try {
      const redisAdapter = await createRedisIoAdapter(app);
      app.useWebSocketAdapter(redisAdapter);
      console.log('Redis adapter enabled for WebSocket scaling');
    } catch (error) {
      console.error('Failed to setup Redis adapter:', error);
      console.log('Falling back to default WebSocket adapter');
    }
  }

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Application is running on: http://localhost:${port}`);
}
void bootstrap();
