import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { StripeProvider } from './stripe-provider';

class ProviderFailure extends Error {
  constructor(readonly statusCode: number, message: string) {
    super(message);
  }
}

jest.mock('stripe', () => ({
  __esModule: true,
  default: Object.assign(jest.fn(), { errors: { StripeError: Error } }),
  Stripe: jest.fn(),
}));

type MockStripe = {
  checkout: { sessions: { create: jest.Mock; expire: jest.Mock } };
  paymentIntents: { create: jest.Mock; cancel: jest.Mock };
  transfers: {
    create: jest.Mock;
    retrieve: jest.Mock;
    list: jest.Mock;
    createReversal: jest.Mock;
  };
  webhooks: {
    constructEvent: jest.Mock;
    generateTestHeaderString: jest.Mock;
  };
  v2: {
    core: {
      accounts: { create: jest.Mock; retrieve: jest.Mock };
    };
  };
  parseEventNotification: jest.Mock;
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
          expire: jest.fn(),
        },
      },
      paymentIntents: {
        create: jest.fn(),
        cancel: jest.fn(),
      },
      webhooks: {
        constructEvent: jest.fn(),
        generateTestHeaderString: jest.fn(),
      },
      transfers: {
        create: jest.fn(),
        retrieve: jest.fn(),
        list: jest.fn(),
        createReversal: jest.fn(),
      },
      v2: {
        core: {
          accounts: { create: jest.fn(), retrieve: jest.fn() },
        },
      },
      parseEventNotification: jest.fn(),
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

  it('creates an allocation transfer with durable identity and source charge', async () => {
    mockStripe.transfers.create.mockResolvedValue({ id: 'tr_1' });

    const result = await provider.createTransfer({
      amount: 9000,
      currency: 'brl',
      destination: 'acct_seller',
      sourceTransaction: 'ch_1',
      orderId: 'order_1',
      transactionId: 'transaction_1',
      paymentGroupId: 'group_1',
      transferGroup: 'freebay:payment-group:group_1',
      idempotencyKey: 'transfer:transaction_1',
    });

    expect(result.isRight()).toBe(true);
    expect(mockStripe.transfers.create).toHaveBeenCalledWith(
      {
        amount: 9000,
        currency: 'brl',
        destination: 'acct_seller',
        source_transaction: 'ch_1',
        transfer_group: 'freebay:payment-group:group_1',
        metadata: {
          orderId: 'order_1',
          transactionId: 'transaction_1',
          paymentGroupId: 'group_1',
          idempotencyKey: 'transfer:transaction_1',
        },
      },
      { idempotencyKey: 'transfer:transaction_1' },
    );
  });

  it.each([400, 429] as const)('preserves Stripe status %s for transfer classification', async (status) => {
    mockStripe.transfers.create.mockRejectedValue(new ProviderFailure(status, 'provider rejected'));

    const result = await provider.createTransfer({
      amount: 9000,
      currency: 'brl',
      destination: 'acct_seller',
      sourceTransaction: 'ch_1',
      orderId: 'order_1',
      transactionId: 'transaction_1',
      transferGroup: 'freebay:order:order_1',
      idempotencyKey: 'transfer:transaction_1',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.statusCode).toBe(status);
  });

  it.each([400, 429] as const)('preserves Stripe status %s for reversal classification', async (status) => {
    mockStripe.transfers.createReversal.mockRejectedValue(new ProviderFailure(status, 'provider rejected'));

    const result = await provider.reverseTransfer(
      'tr_1',
      9000,
      'order_1',
      'transaction_1',
      'reversal:transaction_1',
    );

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.statusCode).toBe(status);
  });

  describe('configuration validation', () => {
    it('throws if STRIPE_WEBHOOK_SECRET is not configured', async () => {
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

    it('throws if STRIPE_SECRET_KEY is not configured', async () => {
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

    it('rejects Stripe test keys in production', async () => {
      await expect(
        Test.createTestingModule({
          providers: [
            StripeProvider,
            {
              provide: ConfigService,
              useValue: {
                get: (key: string) => {
                  if (key === 'STRIPE_WEBHOOK_SECRET') return WEBHOOK_SECRET;
                  if (key === 'STRIPE_SECRET_KEY') return SECRET_KEY;
                  if (key === 'NODE_ENV') return 'production';
                  return undefined;
                },
              },
            },
          ],
        }).compile(),
      ).rejects.toThrow('Stripe test keys are not allowed in production');
    });
  });

  describe('createPaymentSession', () => {
    it('creates a payment session successfully', async () => {
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

    it('handles Stripe API errors', async () => {
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
    it('creates a payment intent successfully', async () => {
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

    it('handles Stripe API errors', async () => {
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

    it('never sends customer_email and passes receipt_email when provided', async () => {
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

    it('passes the idempotencyKey through to the Stripe options', async () => {
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

    it('generates a default idempotencyKey when none is provided', async () => {
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

    it('returns an empty clientSecret when Stripe omits it', async () => {
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

    it('sends receipt_email as undefined when no receiptEmail is provided', async () => {
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

  describe('cancelPendingPayment', () => {
    it('expires a Checkout Session idempotently', async () => {
      mockStripe.checkout.sessions.expire.mockResolvedValue({ id: 'cs_1' });

      const result = await provider.cancelPendingPayment({
        stripeSessionId: 'cs_1',
        idempotencyKey: 'cancel-1',
      });

      expect(result.isRight()).toBe(true);
      expect(mockStripe.checkout.sessions.expire).toHaveBeenCalledWith(
        'cs_1',
        {},
        { idempotencyKey: 'cancel-1' },
      );
    });

    it('cancels a PaymentIntent idempotently', async () => {
      mockStripe.paymentIntents.cancel.mockResolvedValue({ id: 'pi_1' });

      const result = await provider.cancelPendingPayment({
        stripePaymentIntentId: 'pi_1',
        idempotencyKey: 'cancel-2',
      });

      expect(result.isRight()).toBe(true);
      expect(mockStripe.paymentIntents.cancel).toHaveBeenCalledWith(
        'pi_1',
        {},
        { idempotencyKey: 'cancel-2' },
      );
    });
  });

  describe('Connect accounts', () => {
    const account = (transferStatus: string, requirements: Array<{ description: string; minimum_deadline: { status: string } }> = []) => ({
      id: 'acct_1',
      object: 'v2.core.account',
      applied_configurations: ['recipient'],
      configuration: {
        recipient: {
          capabilities: {
            stripe_balance: {
              stripe_transfers: { status: transferStatus },
              payouts: { status: 'active' },
            },
          },
        },
      },
      identity: { country: 'BR' },
      defaults: { currency: 'brl' },
      requirements: { entries: requirements },
    });

    it('preserves recipient Express account creation and includes future requirements', async () => {
      mockStripe.v2.core.accounts.create.mockResolvedValue(account('pending'));

      await provider.createConnectAccount({
        email: 'seller@example.com',
        displayName: 'Seller',
        country: 'BR',
        currency: 'brl',
      });

      expect(mockStripe.v2.core.accounts.create).toHaveBeenCalledWith(
        expect.objectContaining({
          dashboard: 'express',
          identity: { country: 'BR' },
          defaults: {
            currency: 'brl',
            responsibilities: { fees_collector: 'application', losses_collector: 'application' },
          },
          configuration: {
            recipient: { capabilities: { stripe_balance: { stripe_transfers: { requested: true } } } },
          },
          include: ['configuration.recipient', 'identity', 'requirements', 'future_requirements'],
        }),
      );
    });

    it.each([
      ['active', [], 'transfer-ready'],
      ['pending', [], 'onboarding-required'],
      ['pending', [{ description: 'tax_id', minimum_deadline: { status: 'currently_due' } }], 'requirements-due'],
      ['pending', [{ description: 'tax_id', minimum_deadline: { status: 'past_due' } }], 'requirements-due'],
      ['pending', [{ description: 'tax_id', minimum_deadline: { status: 'eventually_due' } }], 'onboarding-required'],
      ['restricted', [], 'restricted'],
      ['unsupported', [], 'restricted'],
    ])('projects %s with requirements into %s', async (transferStatus, requirements, expectedStatus) => {
      mockStripe.v2.core.accounts.retrieve.mockResolvedValue(account(transferStatus, requirements));

      const result = await provider.refreshConnectAccount('acct_1');

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.status).toBe(expectedStatus);
        expect(result.value.requirementsDue).toEqual(
          requirements.filter((entry) => ['currently_due', 'past_due'].includes(entry.minimum_deadline.status)).map((entry) => entry.description),
        );
      }
    });

    it('does not infer restriction from pending status details', async () => {
      mockStripe.v2.core.accounts.retrieve.mockResolvedValue({
        ...account('pending'),
        configuration: {
          recipient: {
            capabilities: {
              stripe_balance: {
                stripe_transfers: { status: 'pending', status_details: [{ code: 'restricted_other' }] },
              },
            },
          },
        },
      });

      const result = await provider.refreshConnectAccount('acct_1');

      expect(result.isRight()).toBe(true);
      if (result.isRight()) expect(result.value.status).toBe('onboarding-required');
    });

    it('projects a closed account as restricted', async () => {
      mockStripe.v2.core.accounts.retrieve.mockResolvedValue({ ...account('active'), closed: true });

      const result = await provider.refreshConnectAccount('acct_1');

      expect(result.isRight()).toBe(true);
      if (result.isRight()) expect(result.value.status).toBe('restricted');
    });
  });

  describe('verifyWebhook', () => {
    it('returns true for valid signature', () => {
      mockStripe.webhooks.constructEvent.mockReturnValue({
        id: 'evt_test',
        type: 'checkout.session.completed',
      });

      const result = provider.verifyWebhook('{"event":"data"}', 'valid-signature');
      expect(result).toBe(true);
    });

    it('returns false for invalid signature', () => {
      mockStripe.webhooks.constructEvent.mockImplementation(() => {
        throw new Error('Invalid signature');
      });

      const result = provider.verifyWebhook('{"event":"data"}', 'invalid-signature');
      expect(result).toBe(false);
    });

    it('returns false for missing signature', () => {
      const result = provider.verifyWebhook('{"event":"data"}', '');
      expect(result).toBe(false);
    });

    it('verifies a v2 thin event after constructEvent rejects it', () => {
      mockStripe.webhooks.constructEvent.mockImplementation(() => {
        throw new Error('Unable to extract timestamp and signatures from header');
      });
      mockStripe.parseEventNotification.mockReturnValue({
        id: 'evt_v2',
        type: 'v2.core.account.updated',
        related_object: { id: 'acct_1', type: 'v2.core.account' },
      });

      expect(provider.verifyWebhook('v2-payload', 'v2-signature')).toBe(true);
      expect(mockStripe.parseEventNotification).toHaveBeenCalledWith(
        'v2-payload',
        'v2-signature',
        WEBHOOK_SECRET,
      );
    });

    it('rejects an invalid v2 signature', () => {
      mockStripe.webhooks.constructEvent.mockImplementation(() => {
        throw new Error('not v1');
      });
      mockStripe.parseEventNotification.mockImplementation(() => {
        throw new Error('Invalid signature');
      });

      expect(provider.verifyWebhook('v2-payload', 'invalid')).toBe(false);
    });
  });

  describe('constructWebhookEvent', () => {
    it('constructs event for valid signature', () => {
      const mockEvent = { id: 'evt_test', type: 'checkout.session.completed' };
      mockStripe.webhooks.constructEvent.mockReturnValue(mockEvent);

      const result = provider.constructWebhookEvent('payload', 'valid-signature');
      expect(result).toEqual(mockEvent);
    });

    it('returns null for invalid signature', () => {
      mockStripe.webhooks.constructEvent.mockImplementation(() => {
        throw new Error('Invalid signature');
      });

      const result = provider.constructWebhookEvent('payload', 'invalid');
      expect(result).toBeNull();
    });
  });
});
