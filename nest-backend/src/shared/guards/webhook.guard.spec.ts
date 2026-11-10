import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { StripeProvider, StripeWebhookEvent } from '@/modules/payments/providers/stripe-provider';
import { createExecutionContext } from '@/shared/testing/test-doubles';
import { WebhookGuard } from './webhook.guard';

describe('WebhookGuard', () => {
  let guard: WebhookGuard;
  const event: StripeWebhookEvent = {
    id: 'evt_v2_account',
    object: 'v2.core.event',
    created: new Date().toISOString(),
    livemode: false,
    type: 'v2.core.account.updated',
    related_object: { id: 'acct_1', type: 'v2.core.account', url: '' },
    fetchRelatedObject: async () => {
      throw new Error('not used');
    },
    fetchEvent: async () => {
      throw new Error('not used');
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebhookGuard,
        {
          provide: StripeProvider,
          useValue: { constructWebhookEvent: jest.fn().mockReturnValue(event) },
        },
      ],
    }).compile();

    guard = module.get(WebhookGuard);
  });

  it('attaches a verified v2 event to the request', async () => {
    const request = {
      headers: { 'stripe-signature': 'valid' },
      rawBody: Buffer.from('{"type":"v2.core.account.updated"}'),
    };

    await expect(guard.canActivate(createExecutionContext({ request }))).resolves.toBe(true);
    expect(request).toHaveProperty('stripeEvent', event);
  });

  it('rejects a request when signature verification returns no event', async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebhookGuard,
        {
          provide: StripeProvider,
          useValue: { constructWebhookEvent: jest.fn().mockReturnValue(null) },
        },
      ],
    }).compile();
    const invalidGuard = module.get(WebhookGuard);
    const request = {
      headers: { 'stripe-signature': 'invalid' },
      rawBody: Buffer.from('{}'),
    };

    await expect(
      invalidGuard.canActivate(createExecutionContext({ request })),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
