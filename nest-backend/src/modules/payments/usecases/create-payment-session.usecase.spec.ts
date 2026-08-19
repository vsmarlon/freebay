import { Test, TestingModule } from '@nestjs/testing';
import { CreatePaymentSessionUseCase } from './create-payment-session.usecase';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { UserRepository } from '../../auth/domain/repositories/user.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { PaymentProvider } from '../domain/providers/payment-provider.interface';
import { NotFoundError, BadRequestError, AppError } from '@/shared/core/errors';
import { right, left } from '@/shared/core/either';

describe('CreatePaymentSessionUseCase', () => {
  let sut: CreatePaymentSessionUseCase;
  let mockOrderRepository: { findById: jest.Mock };
  let mockUserRepository: { findPaymentInfo: jest.Mock };
  let mockTransactionRepository: {
    findByDerivedKey: jest.Mock;
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
      findByDerivedKey: jest.fn().mockResolvedValue(right(null)),
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
        { provide: OrderRepository, useValue: mockOrderRepository },
        { provide: UserRepository, useValue: mockUserRepository },
        { provide: TransactionRepository, useValue: mockTransactionRepository },
        { provide: PaymentProvider, useValue: mockPaymentProvider },
      ],
    }).compile();

    sut = module.get<CreatePaymentSessionUseCase>(CreatePaymentSessionUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should return error if order not found', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(left(new NotFoundError('Order')));

    const result = await sut.execute({
      orderId: 'non-existent-order',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if user is not the buyer', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'different-user',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return error if user has no CPF', async () => {
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

  it('should create payment session successfully', async () => {
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

  it('should handle payment provider failure', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockPaymentProvider.createPaymentSession = jest.fn().mockResolvedValue(
      left(new AppError('PAYMENT_PROVIDER_ERROR', 'Provider error', 500)),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('PAYMENT_PROVIDER_ERROR');
  });

  it('should return existing transaction for duplicate idempotency key', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByDerivedKey = jest.fn().mockResolvedValue(
      right({
        id: 'tx-existing',
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

  it('creates a fresh Checkout Session when a PaymentIntent exists under a different idempotency key (cross-flow isolation)', async () => {
    // The mobile flow stores a PaymentIntent under `pi:${orderId}` and the web
    // flow derives `session:${orderId}`, so the session lookup never finds the
    // pi_ transaction and must not return it as a valid Checkout Session.
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByDerivedKey = jest.fn().mockResolvedValue(right(null));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
      idempotencyKey: 'order-123',
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.stripeSessionId).toBe('cs_test_abc123');
    }
    expect(mockTransactionRepository.findByDerivedKey).toHaveBeenCalledWith('session:order-123');
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalledWith(
      expect.objectContaining({ idempotencyKey: 'session:order-123' }),
    );
  });
});
