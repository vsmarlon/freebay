import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';
import { AbacatePayProvider } from './abacatepay.provider';

describe('AbacatePayProvider', () => {
  describe('verifyWebhook', () => {
    let provider: AbacatePayProvider;
    const WEBHOOK_SECRET = 'test-secret';

    beforeEach(async () => {
      const module: TestingModule = await Test.createTestingModule({
        providers: [
          AbacatePayProvider,
          {
            provide: ConfigService,
            useValue: {
              get: (key: string) => {
                if (key === 'ABACATEPAY_WEBHOOK_SECRET') return WEBHOOK_SECRET;
                if (key === 'ABACATEPAY_API_KEY') return 'test-api-key';
                return undefined;
              },
            },
          },
        ],
      }).compile();

      provider = module.get<AbacatePayProvider>(AbacatePayProvider);
    });

    it('should verify valid signature', () => {
      const body = { event: 'charge.completed' };
      const signature = createHmac('sha256', WEBHOOK_SECRET)
        .update(JSON.stringify(body))
        .digest('hex');

      expect(provider.verifyWebhook(signature, body)).toBe(true);
    });

    it('should reject invalid signature', () => {
      const body = { event: 'charge.completed' };
      expect(provider.verifyWebhook('invalid', body)).toBe(false);
    });

    it('should reject missing signature', () => {
      expect(provider.verifyWebhook('', {})).toBe(false);
    });

    it('should reject tampered body', () => {
      const original = { id: '123' };
      const tampered = { id: '999' };
      const signature = createHmac('sha256', WEBHOOK_SECRET)
        .update(JSON.stringify(original))
        .digest('hex');

      expect(provider.verifyWebhook(signature, tampered)).toBe(false);
    });
  });

  describe('verifyWebhook - no secret', () => {
    it('should throw on module init when webhook secret is not configured', async () => {
      const module = await Test.createTestingModule({
        providers: [
          AbacatePayProvider,
          { provide: ConfigService, useValue: { get: () => '' } },
        ],
      }).compile();

      await expect(module.init()).rejects.toThrow('ABACATEPAY_WEBHOOK_SECRET is not configured');
    });
  });
});
