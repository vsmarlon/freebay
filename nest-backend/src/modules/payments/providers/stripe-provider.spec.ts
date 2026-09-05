import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { StripeProvider } from './stripe-provider';

jest.mock('stripe', () => ({
  __esModule: true,
  default: jest.fn(),
  Stripe: jest.fn(),
}));

type MockStripe = {
  checkout: { sessions: { create: jest.Mock } };
  paymentIntents: { create: jest.Mock };
  webhooks: {
    constructEvent: jest.Mock;
    generateTestHeaderString: jest.Mock;
  };
};

describe('StripeProvider', () => {
  let provider: StripeProvider;
  let mockStripe: MockStripe;

  const WEBHOOK_SECRET = 'whsec_test_secret';
  const SECRET_KEY = 'sk_test_12345';

  beforeEach(async () => {
    mockStripe = {
      checkout: {
        sessions: {
          create: jest.fn(),
        },
      },
      paymentIntents: {
        create: jest.fn(),
      },
      webhooks: {
        constructEvent: jest.fn(),
        generateTestHeaderString: jest.fn(),
      },
    };

    const stripeModule = require('stripe');
    (stripeModule.default as jest.Mock).mockImplementation(() => mockStripe);
    (stripeModule.Stripe as jest.Mock).mockImplementation(() => mockStripe);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StripeProvider,
        {
          provide: ConfigService,
          useValue: {
            get: (key: string) => {
              if (key === 'STRIPE_WEBHOOK_SECRET') return WEBHOOK_SECRET;
              if (key === 'STRIPE_SECRET_KEY') return SECRET_KEY;
              if (key === 'STRIPE_PUBLISHABLE_KEY') return 'pk_test_12345';
              return undefined;
            },
          },
        },
      ],
    }).compile();

    provider = module.get<StripeProvider>(StripeProvider);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('configuration validation', () => {
    it('should throw if STRIPE_WEBHOOK_SECRET is not configured', async () => {
      await expect(
        Test.createTestingModule({
          providers: [
            StripeProvider,
            {
              provide: ConfigService,
              useValue: {
                get: (key: string) => {
                  if (key === 'STRIPE_WEBHOOK_SECRET') return '';
                  if (key === 'STRIPE_SECRET_KEY') return SECRET_KEY;
                  return undefined;
                },
              },
            },
          ],
        }).compile(),
      ).rejects.toThrow('STRIPE_WEBHOOK_SECRET is not configured');
    });

    it('should throw if STRIPE_SECRET_KEY is not configured', async () => {
      await expect(
        Test.createTestingModule({
          providers: [
            StripeProvider,
            {
              provide: ConfigService,
              useValue: {
                get: (key: string) => {
                  if (key === 'STRIPE_WEBHOOK_SECRET') return WEBHOOK_SECRET;
                  if (key === 'STRIPE_SECRET_KEY') return '';
                  return undefined;
                },
              },
            },
          ],
        }).compile(),
      ).rejects.toThrow('STRIPE_SECRET_KEY is not configured');
    });
  });

  describe('createPaymentSession', () => {
    it('should create a payment session successfully', async () => {
      mockStripe.checkout.sessions.create.mockResolvedValue({
        id: 'cs_test_123',
        url: 'https://checkout.stripe.com/pay/cs_test_123',
      });

      const result = await provider.createPaymentSession({
        orderId: 'order-123',
        amount: 10000,
        currency: 'brl',
        customerEmail: 'test@example.com',
        successUrl: 'https://app.freebay.com/success',
        cancelUrl: 'https://app.freebay.com/cancel',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.stripeSessionId).toBe('cs_test_123');
        expect(result.value.checkoutUrl).toBe(
          'https://checkout.stripe.com/pay/cs_test_123',
        );
        expect(result.value.expiresAt).toBeInstanceOf(Date);
      }

      expect(mockStripe.checkout.sessions.create).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: 'payment',
          customer_email: 'test@example.com',
          success_url: 'https://app.freebay.com/success',
          cancel_url: 'https://app.freebay.com/cancel',
          metadata: expect.objectContaining({
            orderId: 'order-123',
          }),
        }),
        expect.any(Object),
      );
    });

    it('should handle Stripe API errors', async () => {
      mockStripe.checkout.sessions.create.mockRejectedValue(
        new Error('Stripe API error: invalid request'),
      );

      const result = await provider.createPaymentSession({
        orderId: 'order-123',
        amount: 10000,
        currency: 'brl',
        customerEmail: 'test@example.com',
        successUrl: 'https://app.freebay.com/success',
        cancelUrl: 'https://app.freebay.com/cancel',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value.code).toBe('PAYMENT_PROVIDER_ERROR');
      }
    });
  });

  describe('createPaymentIntent', () => {
    it('should create a payment intent successfully', async () => {
      mockStripe.paymentIntents.create.mockResolvedValue({
        id: 'pi_test_123',
        client_secret: 'pi_test_123_secret_abc',
      });

      const result = await provider.createPaymentIntent({
        orderId: 'order-123',
        amount: 10000,
        currency: 'brl',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.paymentIntentId).toBe('pi_test_123');
        expect(result.value.clientSecret).toBe('pi_test_123_secret_abc');
      }

      expect(mockStripe.paymentIntents.create).toHaveBeenCalledWith(
        expect.objectContaining({
          amount: 10000,
          currency: 'brl',
          automatic_payment_methods: { enabled: true },
          metadata: expect.objectContaining({
            orderId: 'order-123',
          }),
        }),
        expect.any(Object),
      );
    });

    it('should handle Stripe API errors', async () => {
      mockStripe.paymentIntents.create.mockRejectedValue(
        new Error('Stripe API error: invalid request'),
      );

      const result = await provider.createPaymentIntent({
        orderId: 'order-123',
        amount: 10000,
        currency: 'brl',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value.code).toBe('PAYMENT_PROVIDER_ERROR');
      }
    });

    it('should never send customer_email and should pass receipt_email when provided', async () => {
      mockStripe.paymentIntents.create.mockResolvedValue({
        id: 'pi_test_456',
        client_secret: 'pi_test_456_secret',
      });

      const result = await provider.createPaymentIntent({
        orderId: 'order-456',
        amount: 5000,
        currency: 'brl',
        receiptEmail: 'buyer@example.com',
      });

      expect(result.isRight()).toBe(true);
      expect(mockStripe.paymentIntents.create).toHaveBeenCalledWith(
        expect.objectContaining({
          receipt_email: 'buyer@example.com',
        }),
        expect.any(Object),
      );

      const [createParams] = mockStripe.paymentIntents.create.mock.calls[0];
      expect(createParams).not.toHaveProperty('customer_email');
      expect(Object.keys(createParams)).not.toContain('customer_email');
    });

    it('should pass the idempotencyKey through to the Stripe options', async () => {
      mockStripe.paymentIntents.create.mockResolvedValue({
        id: 'pi_test_789',
        client_secret: 'pi_test_789_secret',
      });

      const result = await provider.createPaymentIntent({
        orderId: 'order-789',
        amount: 3000,
        currency: 'brl',
        idempotencyKey: 'custom-idem-key',
      });

      expect(result.isRight()).toBe(true);
      const [createParams, options] = mockStripe.paymentIntents.create.mock.calls[0];
      expect(options).toEqual({ idempotencyKey: 'custom-idem-key' });
      expect(createParams.metadata).toMatchObject({
        idempotencyKey: 'custom-idem-key',
      });
    });

    it('should generate a default idempotencyKey when none is provided', async () => {
      mockStripe.paymentIntents.create.mockResolvedValue({
        id: 'pi_test_000',
        client_secret: 'pi_test_000_secret',
      });

      const result = await provider.createPaymentIntent({
        orderId: 'order-000',
        amount: 2500,
        currency: 'brl',
      });

      expect(result.isRight()).toBe(true);
      const [createParams, options] = mockStripe.paymentIntents.create.mock.calls[0];
      expect(options).toEqual({ idempotencyKey: 'order-000-pi-2500' });
      expect(createParams.metadata).toMatchObject({
        idempotencyKey: 'order-000-pi-2500',
      });
    });

    it('should return an empty clientSecret when Stripe omits it', async () => {
      mockStripe.paymentIntents.create.mockResolvedValue({
        id: 'pi_test_missing_secret',
      });

      const result = await provider.createPaymentIntent({
        orderId: 'order-missing',
        amount: 1000,
        currency: 'brl',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) expect(result.value.clientSecret).toBe('');
    });

    it('should send receipt_email as undefined when no receiptEmail is provided', async () => {
      mockStripe.paymentIntents.create.mockResolvedValue({
        id: 'pi_test_none',
        client_secret: 'pi_test_none_secret',
      });

      const result = await provider.createPaymentIntent({
        orderId: 'order-none',
        amount: 1000,
        currency: 'brl',
      });

      expect(result.isRight()).toBe(true);
      const [createParams] = mockStripe.paymentIntents.create.mock.calls[0];
      // The provider always includes the key; the Stripe SDK strips undefined.
      expect(createParams.receipt_email).toBeUndefined();
    });
  });

  describe('verifyWebhook', () => {
    it('should return true for valid signature', () => {
      mockStripe.webhooks.constructEvent.mockReturnValue({
        id: 'evt_test',
        type: 'checkout.session.completed',
      });

      const result = provider.verifyWebhook('{"event":"data"}', 'valid-signature');
      expect(result).toBe(true);
    });

    it('should return false for invalid signature', () => {
      mockStripe.webhooks.constructEvent.mockImplementation(() => {
        throw new Error('Invalid signature');
      });

      const result = provider.verifyWebhook('{"event":"data"}', 'invalid-signature');
      expect(result).toBe(false);
    });

    it('should return false for missing signature', () => {
      const result = provider.verifyWebhook('{"event":"data"}', '');
      expect(result).toBe(false);
    });
  });

  describe('constructWebhookEvent', () => {
    it('should construct event for valid signature', () => {
      const mockEvent = { id: 'evt_test', type: 'checkout.session.completed' };
      mockStripe.webhooks.constructEvent.mockReturnValue(mockEvent);

      const result = provider.constructWebhookEvent('payload', 'valid-signature');
      expect(result).toEqual(mockEvent);
    });

    it('should return null for invalid signature', () => {
      mockStripe.webhooks.constructEvent.mockImplementation(() => {
        throw new Error('Invalid signature');
      });

      const result = provider.constructWebhookEvent('payload', 'invalid');
      expect(result).toBeNull();
    });
  });
});
