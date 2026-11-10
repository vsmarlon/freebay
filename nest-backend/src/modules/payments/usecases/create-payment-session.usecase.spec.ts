import { Test, TestingModule } from '@nestjs/testing';
import { CreatePaymentSessionUseCase } from './create-payment-session.usecase';
import { OrderDatabaseRepository } from '../../orders/data/repositories/order-database.repository';
import { UserDatabaseRepository } from '@/modules/users';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { StripeProvider } from '../providers/stripe-provider';
import { NotFoundError, BadRequestError, PaymentProviderError } from '@/shared/core/errors';
import { right, left } from '@/shared/core/either';

describe('CreatePaymentSessionUseCase', () => {
  let sut: CreatePaymentSessionUseCase;
  let mockOrderRepository: { findById: jest.Mock };
  let mockUserRepository: { findPaymentInfo: jest.Mock };
  let mockTransactionRepository: {
    findByOrderId: jest.Mock;
    reservePaymentSessionAttempt: jest.Mock;
    attachPaymentSession: jest.Mock;
    upsertTransaction: jest.Mock;
  };
  let mockPaymentProvider: { createPaymentSession: jest.Mock; retrievePaymentSession: jest.Mock };

  const mockOrder = {
    id: 'order-123',
    buyerId: 'user-buyer',
    sellerId: 'user-seller',
    amount: 10000,
    platformFee: 1000,
    sellerAmount: 9000,
    status: 'PENDING',
  };

  beforeEach(async () => {
    mockOrderRepository = { findById: jest.fn() };
    mockUserRepository = {
      findPaymentInfo: jest.fn().mockResolvedValue(
        right({ displayName: 'John Doe', email: 'john@example.com', cpf: '12345678901' }),
      ),
    };
    mockTransactionRepository = {
      findByOrderId: jest.fn().mockResolvedValue(right(null)),
      reservePaymentSessionAttempt: jest.fn().mockResolvedValue(right(true)),
      attachPaymentSession: jest.fn().mockResolvedValue(right(true)),
      upsertTransaction: jest.fn().mockResolvedValue(right(undefined)),
    };
    mockPaymentProvider = {
      createPaymentSession: jest.fn().mockResolvedValue(
        right({
          stripeSessionId: 'cs_test_abc123',
          checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_abc123',
          expiresAt: new Date(),
        }),
      ),
      retrievePaymentSession: jest.fn().mockResolvedValue(right({
        stripeSessionId: 'cs_test_abc123', checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_abc123',
        status: 'open', mode: 'payment', paymentStatus: 'unpaid',
        amountTotal: 10000, currency: 'brl', orderId: 'order-123', paymentGroupId: null,
        buyerId: 'user-buyer', idempotencyKey: 'session:order-123', expiresAt: new Date(),
      })),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePaymentSessionUseCase,
        { provide: OrderDatabaseRepository, useValue: mockOrderRepository },
        { provide: UserDatabaseRepository, useValue: mockUserRepository },
        { provide: TransactionDatabaseRepository, useValue: mockTransactionRepository },
        { provide: StripeProvider, useValue: mockPaymentProvider },
      ],
    }).compile();

    sut = module.get(CreatePaymentSessionUseCase);
  });

  it('returns error if order not found', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(left(new NotFoundError('Order')));

    const result = await sut.execute({
      orderId: 'non-existent-order',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns error if user is not the buyer', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'different-user',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('returns error if user has no CPF', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockUserRepository.findPaymentInfo = jest.fn().mockResolvedValue(
      right({ displayName: 'John', email: 'john@example.com', cpf: null }),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
      expect(result.value.message).toBe('CPF é obrigatório para pagamento via Checkout. Atualize seu perfil.');
    }
  });

  it('creates payment session successfully', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.stripeSessionId).toBe('cs_test_abc123');
      expect(result.value.checkoutUrl).toBe('https://checkout.stripe.com/pay/cs_test_abc123');
      expect(result.value.orderId).toBe('order-123');
    }
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: 'order-123',
        buyerId: 'user-buyer',
        amount: 10000,
        currency: 'brl',
        customerEmail: 'john@example.com',
      }),
    );
    expect(mockPaymentProvider.retrievePaymentSession).toHaveBeenCalledWith('cs_test_abc123');
    expect(mockTransactionRepository.reservePaymentSessionAttempt.mock.invocationCallOrder[0])
      .toBeLessThan(mockPaymentProvider.createPaymentSession.mock.invocationCallOrder[0]);
    expect(mockPaymentProvider.retrievePaymentSession.mock.invocationCallOrder[0])
      .toBeLessThan(mockTransactionRepository.attachPaymentSession.mock.invocationCallOrder[0]);
  });

  it('does not create a second Session for an unresolved durable attempt', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByOrderId.mockResolvedValue(right({
      id: 'tx-attempt', status: 'PENDING', externalId: null,
      idempotencyKey: 'session:order-123', checkoutUrl: null,
    }));

    const result = await sut.execute({ orderId: 'order-123', userId: 'user-buyer' });

    expect(result.isLeft()).toBe(true);
    expect(mockPaymentProvider.createPaymentSession).not.toHaveBeenCalled();
    expect(mockTransactionRepository.reservePaymentSessionAttempt).not.toHaveBeenCalled();
  });

  it('does not retry the provider after local attachment fails for a created Session', async () => {
    mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
    mockTransactionRepository.attachPaymentSession.mockResolvedValueOnce(left(new PaymentProviderError('database unavailable')));
    const input = { orderId: 'order-123', userId: 'user-buyer' };

    const first = await sut.execute(input);
    mockTransactionRepository.findByOrderId.mockResolvedValue(right({
      id: 'tx-attempt', status: 'PENDING', externalId: null,
      idempotencyKey: 'session:order-123', checkoutUrl: null,
    }));
    const retry = await sut.execute(input);

    expect(first.isLeft()).toBe(true);
    expect(retry.isLeft()).toBe(true);
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalledTimes(1);
  });

  it('does not attach a Session whose canonical metadata belongs to another buyer', async () => {
    mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
    mockPaymentProvider.retrievePaymentSession.mockResolvedValue(right({
      stripeSessionId: 'cs_test_abc123', checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_abc123',
      status: 'open', mode: 'payment', paymentStatus: 'unpaid', amountTotal: 10000, currency: 'brl',
      orderId: 'order-123', paymentGroupId: null, buyerId: 'other-buyer',
      idempotencyKey: 'session:order-123', expiresAt: new Date(),
    }));

    const result = await sut.execute({ orderId: 'order-123', userId: 'user-buyer' });

    expect(result.isLeft()).toBe(true);
    expect(mockTransactionRepository.attachPaymentSession).not.toHaveBeenCalled();
  });

  it.each([undefined, '', '   '])(
    'uses the authenticated email when customerEmail is %p',
    async (customerEmail) => {
      mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));

      const result = await sut.execute({
        orderId: 'order-123',
        userId: 'user-buyer',
        customerEmail,
      });

      expect(result.isRight()).toBe(true);
      expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalledWith(
        expect.objectContaining({ customerEmail: 'john@example.com' }),
      );
    },
  );

  it('trims a non-empty customer email before sending it to the provider', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
      customerEmail: '  buyer@example.com  ',
    });

    expect(result.isRight()).toBe(true);
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalledWith(
      expect.objectContaining({ customerEmail: 'buyer@example.com' }),
    );
  });

  it('handles payment provider failure', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockPaymentProvider.createPaymentSession = jest.fn().mockResolvedValue(
      left(new PaymentProviderError('Provider error', 500)),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('PAYMENT_PROVIDER_ERROR');
  });

  it('returns existing transaction for duplicate idempotency key', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByOrderId = jest.fn().mockResolvedValue(
      right({
        id: 'tx-existing',
        status: 'PENDING',
        externalId: 'cs_existing_session',
        checkoutUrl: 'https://checkout.stripe.com/pay/cs_existing',
        checkoutExpiresAt: new Date('2026-03-30T12:00:00Z'),
      }),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
      idempotencyKey: 'custom-key-123',
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.stripeSessionId).toBe('cs_existing_session');
    }
    expect(mockPaymentProvider.createPaymentSession).not.toHaveBeenCalled();
  });

  it('creates a fresh Checkout Session when the order has no transaction yet', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByOrderId = jest.fn().mockResolvedValue(right(null));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
      idempotencyKey: 'order-123',
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.stripeSessionId).toBe('cs_test_abc123');
    }
    expect(mockTransactionRepository.findByOrderId).toHaveBeenCalledWith('order-123');
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalledWith(
      expect.objectContaining({ idempotencyKey: 'session:order-123' }),
    );
  });

  it('refuses to open a Checkout Session while a PaymentIntent is active on the same order', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByOrderId = jest.fn().mockResolvedValue(
      right({ id: 'tx-pi', status: 'PENDING', externalId: 'pi_active_intent' }),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
      idempotencyKey: 'order-123',
    });

    expect(result.isLeft()).toBe(true);
    expect(mockPaymentProvider.createPaymentSession).not.toHaveBeenCalled();
  });

  it('refuses to reopen a Checkout Session on an already PAID order', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByOrderId = jest.fn().mockResolvedValue(
      right({ id: 'tx-paid', status: 'PAID', externalId: 'cs_paid_session' }),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
      idempotencyKey: 'order-123',
    });

    expect(result.isLeft()).toBe(true);
    expect(mockPaymentProvider.createPaymentSession).not.toHaveBeenCalled();
  });

  it('refuses to pay an order that is no longer PENDING', async () => {
    mockOrderRepository.findById = jest
      .fn()
      .mockResolvedValue(right({ ...mockOrder, status: 'CANCELLED' }));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
      idempotencyKey: 'order-123',
    });

    expect(result.isLeft()).toBe(true);
    expect(mockPaymentProvider.createPaymentSession).not.toHaveBeenCalled();
  });
});
