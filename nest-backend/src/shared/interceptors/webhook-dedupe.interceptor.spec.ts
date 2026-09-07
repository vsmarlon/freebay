import { Test, TestingModule } from '@nestjs/testing';
import { CallHandler, ExecutionContext } from '@nestjs/common';
import { createExecutionContext } from '@/shared/testing/test-doubles';
import { of, throwError, lastValueFrom } from 'rxjs';
import { WebhookDedupeInterceptor } from './webhook-dedupe.interceptor';
import { RedisService } from '@/shared/infra/redis/redis.service';

describe('WebhookDedupeInterceptor', () => {
  let interceptor: WebhookDedupeInterceptor;
  let mockRedis: { exists: jest.Mock; add: jest.Mock };

  const createContext = (stripeEvent: { id: string } | undefined): ExecutionContext => {
    const request = { stripeEvent };
    return createExecutionContext({ request });
  };

  beforeEach(async () => {
    mockRedis = {
      exists: jest.fn().mockResolvedValue(false),
      add: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebhookDedupeInterceptor,
        { provide: RedisService, useValue: mockRedis },
      ],
    }).compile();

    interceptor = module.get<WebhookDedupeInterceptor>(WebhookDedupeInterceptor);
  });

  it('should skip the handler and return processed false when the event key already exists', async () => {
    mockRedis.exists.mockResolvedValue(true);
    const handler: CallHandler = { handle: jest.fn() };

    const result = await lastValueFrom(
      await interceptor.intercept(createContext({ id: 'evt_123' }), handler),
    );

    expect(result).toEqual({ processed: false });
    expect(handler.handle).not.toHaveBeenCalled();
    expect(mockRedis.add).not.toHaveBeenCalled();
  });

  it('should run the handler and record the key after a successful response', async () => {
    const handler: CallHandler = { handle: jest.fn(() => of({ processed: true })) };

    const result = await lastValueFrom(
      await interceptor.intercept(createContext({ id: 'evt_123' }), handler),
    );

    expect(result).toEqual({ processed: true });
    expect(handler.handle).toHaveBeenCalled();
    expect(mockRedis.add).toHaveBeenCalledWith('webhook:evt_123', '1', 86400);
  });

  it('should not record the key when the handler throws', async () => {
    const handler: CallHandler = { handle: jest.fn(() => throwError(() => new Error('boom'))) };

    await expect(
      lastValueFrom(await interceptor.intercept(createContext({ id: 'evt_123' }), handler)),
    ).rejects.toThrow('boom');

    expect(mockRedis.add).not.toHaveBeenCalled();
  });
});
