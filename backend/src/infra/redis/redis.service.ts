import Redis from 'ioredis';
import { env } from '@/env';

class RedisService {
  private client: Redis | null = null;

  getInstance(): Redis {
    if (!this.client) {
      this.client = new Redis({
        host: env.REDIS_HOST,
        port: env.REDIS_PORT,
        password: env.REDIS_PASSWORD || undefined,
        lazyConnect: true,
      });
    }
    return this.client;
  }

  async connect(): Promise<void> {
    const redis = this.getInstance();
    await redis.connect();
  }
}

export const redisService = new RedisService();
