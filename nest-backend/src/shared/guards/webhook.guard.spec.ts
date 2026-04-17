import { Test, TestingModule } from '@nestjs/testing';
import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { WebhookGuard } from './webhook.guard';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { AbacatePayProvider } from '@/modules/payments/providers/abacatepay.provider';

describe('WebhookGuard', () => {
  let guard: WebhookGuard;
  let mockRedis: { exists: jest.Mock; add: jest.Mock };
  let mockAbacatePay: { verifyWebhook: jest.Mock };

  const createContext = (headers: Record<string, string> = {}, body = {}): ExecutionContext => ({
    switchToHttp: () => ({
      getRequest: () => ({ headers, body }),
    }),
  }) as ExecutionContext;

  beforeEach(async () => {
    mockRedis = {
      exists: jest.fn().mockResolvedValue(false),
      add: jest.fn().mockResolvedValue(undefined),
    };

    mockAbacatePay = {
      verifyWebhook: jest.fn().mockReturnValue(true),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebhookGuard,
        { provide: RedisService, useValue: mockRedis },
        { provide: AbacatePayProvider, useValue: mockAbacatePay },
      ],
    }).compile();

    guard = module.get<WebhookGuard>(WebhookGuard);
  });

  it('should allow valid webhook', async () => {
    const ctx = createContext(
      { 'x-webhook-signature': 'valid', 'x-webhook-id': 'wh-123' },
      { event: 'charge.completed' },
    );

    expect(await guard.canActivate(ctx)).toBe(true);
    expect(mockRedis.add).toHaveBeenCalledWith('webhook:wh-123', '1', 86400);
  });

  it('should reject duplicate webhook', async () => {
    mockRedis.exists.mockResolvedValue(true);

    const ctx = createContext({ 'x-webhook-id': 'already-done' });

    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
    expect(mockAbacatePay.verifyWebhook).not.toHaveBeenCalled();
  });

  it('should reject invalid signature', async () => {
    mockAbacatePay.verifyWebhook.mockReturnValue(false);

    const ctx = createContext({ 'x-webhook-signature': 'bad' });

    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });

  it('should work without webhook id', async () => {
    const ctx = createContext({ 'x-webhook-signature': 'valid' });

    expect(await guard.canActivate(ctx)).toBe(true);
    expect(mockRedis.exists).not.toHaveBeenCalled();
    expect(mockRedis.add).not.toHaveBeenCalled();
  });
});
