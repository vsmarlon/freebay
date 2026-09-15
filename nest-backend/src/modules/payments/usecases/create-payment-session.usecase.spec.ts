import { Test, TestingModule } from '@nestjs/testing';
import { CreatePaymentSessionUseCase } from './create-payment-session.usecase';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { UserDatabaseRepository } from '../../auth/data/repositories/user-database.repository';
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
    upsertTransaction: jest.Mock;
  };
  let mockPaymentProvider: { createPaymentSession: jest.Mock };

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
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePaymentSessionUseCase,
        { provide: PrismaOrderRepository, useValue: mockOrderRepository },
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
        amount: 10000,
        currency: 'brl',
        customerEmail: 'john@example.com',
      }),
    );
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
