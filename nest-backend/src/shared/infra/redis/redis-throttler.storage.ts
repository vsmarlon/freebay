import { Injectable } from '@nestjs/common';
import type { ThrottlerStorage } from '@nestjs/throttler';
import { RedisService } from './redis.service';

@Injectable()
export class RedisThrottlerStorage implements ThrottlerStorage {
  constructor(private readonly redis: RedisService) {}

  increment(key: string, ttl: number, limit: number, blockDuration: number, throttlerName: string) {
    return this.redis.incrementThrottle(key, ttl, limit, blockDuration, throttlerName);
  }
}
