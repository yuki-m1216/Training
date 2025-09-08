import { IoAdapter } from '@nestjs/platform-socket.io';
import { ServerOptions, Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import { INestApplication } from '@nestjs/common';

export class RedisIoAdapter extends IoAdapter {
  private adapterConstructor: ReturnType<typeof createAdapter>;

  async connectToRedis(): Promise<void> {
    const pubClient = createClient({
      url: process.env.REDIS_URL || 'redis://localhost:6379',
    });
    const subClient = pubClient.duplicate();

    await Promise.all([pubClient.connect(), subClient.connect()]);

    this.adapterConstructor = createAdapter(pubClient, subClient);
  }

  createIOServer(port: number, options?: ServerOptions): Server {
    const server = super.createIOServer(port, options) as Server;
    server.adapter(this.adapterConstructor);
    return server;
  }

  create(
    port: number,
    options?: ServerOptions & { namespace?: string; server?: any },
  ): any {
    const server = super.create(port, options);
    return server;
  }
}

export async function createRedisIoAdapter(
  app: INestApplication,
): Promise<RedisIoAdapter> {
  const adapter = new RedisIoAdapter(app);
  await adapter.connectToRedis();
  return adapter;
}
