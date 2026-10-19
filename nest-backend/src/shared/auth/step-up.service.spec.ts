import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { StepUpService } from './step-up.service';

describe('StepUpService', () => {
  it('binds proof to the exact subject, purpose and resource, then consumes once', async () => {
    const consumed = new Set<string>();
    const redis = {
      setIfAbsent: jest.fn(async (key: string) => {
        if (consumed.has(key)) return false;
        consumed.add(key);
        return true;
      }),
    };
    const module = await Test.createTestingModule({
      providers: [
        StepUpService,
        { provide: JwtService, useValue: new JwtService({ secret: 'test-secret' }) },
        { provide: ConfigService, useValue: new ConfigService({ JWT_SECRET: 'test-secret' }) },
        { provide: RedisService, useValue: redis },
      ],
    }).compile();
    const service = module.get(StepUpService);
    const issued = await service.issue('user-1', 'cancel_order', 'order-1');

    expect(await service.consume(issued.stepUpToken, 'user-1', 'cancel_order', 'order-2')).toBe(false);
    expect(await service.consume(issued.stepUpToken, 'user-2', 'cancel_order', 'order-1')).toBe(false);
    expect(await service.consume(issued.stepUpToken, 'user-1', 'delete_account')).toBe(false);
    expect(await service.consume(issued.stepUpToken, 'user-1', 'cancel_order', 'order-1')).toBe(true);
    expect(await service.consume(issued.stepUpToken, 'user-1', 'cancel_order', 'order-1')).toBe(false);
  });
});
