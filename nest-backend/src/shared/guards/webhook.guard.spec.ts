import { Test, TestingModule } from '@nestjs/testing';
import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { WebhookGuard } from './webhook.guard';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';

describe('WebhookGuard', () => {
  let guard: WebhookGuard;
  let mockStripeProvider: { constructWebhookEvent: jest.Mock };

  const mockEvent = { id: 'evt_test', type: 'checkout.session.completed' };

  const createContext = (
    headers: Record<string, string> = {},
    rawBody = '',
  ): ExecutionContext => {
    const request = { headers, rawBody };
    return {
      switchToHttp: () => ({
        getRequest: () => request,
      }),
    } as ExecutionContext;
  };

  beforeEach(async () => {
    mockStripeProvider = {
      constructWebhookEvent: jest.fn().mockReturnValue(mockEvent),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebhookGuard,
        { provide: StripeProvider, useValue: mockStripeProvider },
      ],
    }).compile();

    guard = module.get<WebhookGuard>(WebhookGuard);
  });

  it('should allow valid webhook and attach the Stripe event', async () => {
    const ctx = createContext({ 'stripe-signature': 'valid' }, '{"event":"data"}');

    expect(await guard.canActivate(ctx)).toBe(true);
    expect(mockStripeProvider.constructWebhookEvent).toHaveBeenCalledWith(
      '{"event":"data"}',
      'valid',
    );
    const request = ctx.switchToHttp().getRequest();
    expect(request.stripeEvent).toEqual(mockEvent);
  });

  it('should reject invalid signature', async () => {
    mockStripeProvider.constructWebhookEvent.mockReturnValue(null);

    const ctx = createContext({ 'stripe-signature': 'bad' });

    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });
});
