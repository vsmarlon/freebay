import { Test, TestingModule } from '@nestjs/testing';
import { CreatePaymentIntentUseCase } from './create-payment-intent.usecase';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { UserRepository } from '../../auth/domain/repositories/user.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { PaymentProvider } from '../domain/providers/payment-provider.interface';
import { NotFoundError, BadRequestError, AppError } from '@/shared/core/errors';
import { right, left } from '@/shared/core/either';

describe('CreatePaymentIntentUseCase', () => {
  let sut: CreatePaymentIntentUseCase;
  let mockOrderRepository: { findById: jest.Mock };
  let mockUserRepository: { findPaymentInfo: jest.Mock };
  let mockTransactionRepository: {
    findByDerivedKey: jest.Mock;
    upsertTransaction: jest.Mock;
  };
  let mockPaymentProvider: { createPaymentIntent: jest.Mock };

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
        right({ displayName: 'John Doe', email: 'john@example.com', cpf: null }),
      ),
    };
    mockTransactionRepository = {
      findByDerivedKey: jest.fn().mockResolvedValue(right(null)),
      upsertTransaction: jest.fn().mockResolvedValue(right(undefined)),
    };
    mockPaymentProvider = {
      createPaymentIntent: jest.fn().mockResolvedValue(
        right({
          paymentIntentId: 'pi_test_abc123',
          clientSecret: 'pi_test_abc123_secret',
        }),
      ),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePaymentIntentUseCase,
        { provide: OrderRepository, useValue: mockOrderRepository },
        { provide: UserRepository, useValue: mockUserRepository },
        { provide: TransactionRepository, useValue: mockTransactionRepository },
        { provide: PaymentProvider, useValue: mockPaymentProvider },
      ],
    }).compile();

    sut = module.get<CreatePaymentIntentUseCase>(CreatePaymentIntentUseCase);
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

  it('should NOT require CPF for mobile card-only PaymentIntent flow', async () => {
    // CPF is only required for Checkout Session (PIX). Mobile card-only must succeed without it.
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockUserRepository.findPaymentInfo = jest.fn().mockResolvedValue(
      right({ displayName: 'John', email: 'john@example.com', cpf: null }),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isRight()).toBe(true);
    expect(mockPaymentProvider.createPaymentIntent).toHaveBeenCalled();
  });

  it('should return error if a Checkout Session (cs_) is already active', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByDerivedKey = jest.fn().mockResolvedValue(
      right({
        id: 'tx-existing',
        orderId: 'order-123',
        externalId: 'cs_existing_session',
        status: 'PENDING',
        idempotencyKey: 'pi:order-123',
      }),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
      expect(result.value.message).toBe(
        'A Checkout Session is already active for this order. Complete it in the browser or wait for it to expire.',
      );
    }
    expect(mockPaymentProvider.createPaymentIntent).not.toHaveBeenCalled();
  });

  it('should return error if order is already paid', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByDerivedKey = jest.fn().mockResolvedValue(
      right({
        id: 'tx-paid',
        orderId: 'order-123',
        externalId: 'pi_existing_123',
        status: 'PAID',
        idempotencyKey: 'pi:order-123',
      }),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
      expect(result.value.message).toBe('Order already paid');
    }
  });

  it('should create payment intent successfully for a fresh order', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.paymentIntentClientSecret).toBe('pi_test_abc123_secret');
      expect(result.value.orderId).toBe('order-123');
    }
    expect(mockPaymentProvider.createPaymentIntent).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: 'order-123',
        amount: 10000,
        currency: 'brl',
        receiptEmail: 'john@example.com',
        idempotencyKey: 'pi:order-123',
      }),
    );
    expect(mockTransactionRepository.upsertTransaction).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: 'order-123',
        externalId: 'pi_test_abc123',
        paymentMethod: 'CREDIT_CARD',
        idempotencyKey: 'pi:order-123',
      }),
    );
  });

  it('should handle payment provider failure', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockPaymentProvider.createPaymentIntent = jest.fn().mockResolvedValue(
      left(new AppError('PAYMENT_PROVIDER_ERROR', 'Provider error', 500)),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('PAYMENT_PROVIDER_ERROR');
  });

  it('should return NotFoundError when the order repository resolves null', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(null));

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return "Order is not payable" for a FAILED transaction', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockTransactionRepository.findByDerivedKey = jest.fn().mockResolvedValue(
      right({
        id: 'tx-failed',
        orderId: 'order-123',
        externalId: 'pi_failed_123',
        status: 'FAILED',
        idempotencyKey: 'pi:order-123',
      }),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
      expect(result.value.message).toBe('Order is not payable');
    }
    expect(mockPaymentProvider.createPaymentIntent).not.toHaveBeenCalled();
  });

  it('should not upsert a transaction row when the provider fails', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(right(mockOrder));
    mockPaymentProvider.createPaymentIntent = jest.fn().mockResolvedValue(
      left(new AppError('PAYMENT_PROVIDER_ERROR', 'Provider error', 500)),
    );

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'user-buyer',
    });

    expect(result.isLeft()).toBe(true);
    expect(mockTransactionRepository.upsertTransaction).not.toHaveBeenCalled();
  });
});
