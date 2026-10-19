import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { createHash } from 'node:crypto';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly redis: Redis;

  constructor(private config: ConfigService) {
    const url = this.config.get<string>('REDIS_URL');
    this.redis = url
      ? new Redis(url, { lazyConnect: true })
      : new Redis({
          host: this.config.get('REDIS_HOST', 'localhost'),
          port: this.config.get('REDIS_PORT', 6379),
          password: this.config.get('REDIS_PASSWORD'),
          lazyConnect: true,
        });
  }

  async onModuleDestroy() {
    await this.redis.quit();
  }

  async add(key: string, value: string, ttlSeconds?: number): Promise<void> {
    if (ttlSeconds) {
      await this.redis.setex(key, ttlSeconds, value);
    } else {
      await this.redis.set(key, value);
    }
  }

  async setIfAbsent(key: string, value: string, ttlSeconds: number): Promise<boolean> {
    return (await this.redis.set(key, value, 'EX', ttlSeconds, 'NX')) === 'OK';
  }

  async get(key: string): Promise<string | null> {
    return this.redis.get(key);
  }

  async del(key: string): Promise<void> {
    await this.redis.del(key);
  }

  async exists(key: string): Promise<boolean> {
    const result = await this.redis.exists(key);
    return result === 1;
  }

  async incrementWithExpiry(key: string, ttlSeconds: number): Promise<number> {
    const result = await this.redis.multi().incr(key).expire(key, ttlSeconds).exec();
    const increment = result?.[0]?.[1];
    return typeof increment === 'number' ? increment : Number(increment ?? 0);
  }

  async ping(): Promise<string> {
    return this.redis.ping();
  }

  async eval(script: string, keys: string[], args: string[]): Promise<number> {
    const result: unknown = await this.redis.eval(script, keys.length, ...keys, ...args);
    if (typeof result !== 'number') throw new Error('Unexpected Redis script result');
    return result;
  }

  async incrementThrottle(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ): Promise<{ totalHits: number; timeToExpire: number; isBlocked: boolean; timeToBlockExpire: number }> {
    const digest = createHash('sha256').update(`${throttlerName}:${key}`).digest('hex');
    const script = [
      "local blocked = redis.call('PTTL', KEYS[2])",
      'if blocked > 0 then return {tonumber(redis.call("GET", KEYS[1]) or "0"), tonumber(redis.call("PTTL", KEYS[1])), 1, blocked} end',
      "local hits = redis.call('INCR', KEYS[1])",
      "if hits == 1 then redis.call('PEXPIRE', KEYS[1], ARGV[1]) end",
      'local expires = redis.call("PTTL", KEYS[1])',
      'if hits > tonumber(ARGV[2]) then redis.call("SET", KEYS[2], "1", "PX", ARGV[3]); return {hits, expires, 1, tonumber(ARGV[3])} end',
      'return {hits, expires, 0, 0}',
    ].join('\n');
    const result: unknown = await this.redis.eval(
      script, 2, `throttle:${digest}:hits`, `throttle:${digest}:block`, ttl, limit, blockDuration,
    );
    if (!Array.isArray(result) || result.length !== 4 || !result.every((item) => typeof item === 'number')) {
      throw new Error('Unexpected Redis throttle result');
    }
    const [totalHits, expiry, isBlocked, blockExpiry] = result;
    return {
      totalHits,
      timeToExpire: Math.max(0, Math.ceil(expiry / 1000)),
      isBlocked: isBlocked === 1,
      timeToBlockExpire: Math.max(0, Math.ceil(blockExpiry / 1000)),
    };
  }
}
