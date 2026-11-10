import { createHash, randomUUID } from 'node:crypto';
import { ConfigService } from '@nestjs/config';
import { RedisService } from './redis.service';
import { RedisThrottlerStorage } from './redis-throttler.storage';

const delay = (milliseconds: number) => new Promise((resolve) => setTimeout(resolve, milliseconds));

describe('Redis throttler shared storage (guarded integration)', () => {
  const throttlerName = 'infra-integration';
  const requestKey = `audit:${process.pid}:${randomUUID()}`;
  const digest = createHash('sha256').update(`${throttlerName}:${requestKey}`).digest('hex');
  const redisA = new RedisService(new ConfigService(process.env));
  const redisB = new RedisService(new ConfigService(process.env));
  const storageA = new RedisThrottlerStorage(redisA);
  const storageB = new RedisThrottlerStorage(redisB);
  let redisAClosed = false;

  afterAll(async () => {
    try {
      await redisB.del(`throttle:${digest}:hits`);
      await redisB.del(`throttle:${digest}:block`);
    } finally {
      await Promise.all([
        ...(redisAClosed ? [] : [redisA.onModuleDestroy()]),
        redisB.onModuleDestroy(),
      ]);
    }
  });

  it('shares quota, preserves fixed-window expiry, resets after expiry, and fails closed', async () => {
    const first = await storageA.increment(requestKey, 2000, 2, 700, throttlerName);
    expect(first).toMatchObject({ totalHits: 1, isBlocked: false });

    await delay(1100);
    const second = await storageB.increment(requestKey, 2000, 2, 700, throttlerName);
    expect(second.totalHits).toBe(2);
    expect(second.isBlocked).toBe(false);
    expect(second.timeToExpire).toBeLessThan(first.timeToExpire);

    const overLimit = await storageA.increment(requestKey, 2000, 2, 700, throttlerName);
    expect(overLimit).toMatchObject({ totalHits: 3, isBlocked: true });
    expect(overLimit.timeToBlockExpire).toBeGreaterThan(0);
    await expect(storageB.increment(requestKey, 2000, 2, 700, throttlerName)).resolves.toMatchObject({
      totalHits: 3,
      isBlocked: true,
    });

    await delay(1100);
    const reset = await storageB.increment(requestKey, 2000, 2, 700, throttlerName);
    expect(reset).toMatchObject({ totalHits: 1, isBlocked: false });

    await redisA.ping();
    await redisA.onModuleDestroy();
    redisAClosed = true;
    await expect(storageA.increment(requestKey, 2000, 2, 700, throttlerName)).rejects.toThrow();
  }, 15000);
});
