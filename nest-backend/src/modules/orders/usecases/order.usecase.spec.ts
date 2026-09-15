import { Test, TestingModule } from '@nestjs/testing';
import { ConfirmDeliveryUseCase } from './confirm-delivery.usecase';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { NotFoundError, InvalidOrderStateError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';

describe('ConfirmDeliveryUseCase', () => {
  let sut: ConfirmDeliveryUseCase;
  let mockOrderRepository: { findById: jest.Mock; confirmDelivery: jest.Mock };

  beforeEach(async () => {
    mockOrderRepository = {
      findById: jest.fn(),
      confirmDelivery: jest.fn().mockResolvedValue(right(undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConfirmDeliveryUseCase,
        { provide: PrismaOrderRepository, useValue: mockOrderRepository },
        { provide: SellerPayoutService, useValue: { payoutForOrder: jest.fn() } },
      ],
    }).compile();

    sut = module.get<ConfirmDeliveryUseCase>(ConfirmDeliveryUseCase);
  });

  it('confirms delivery when order is CONFIRMED or DELIVERED and user is buyer', async () => {
    mockOrderRepository.findById.mockResolvedValue(
      right({
        id: 'order-123',
        buyerId: 'user-123',
        sellerId: 'seller-123',
        status: 'CONFIRMED',
        sellerAmount: 9000,
      }),
    );

    const input = {
      orderId: 'order-123',
      buyerId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.sellerAmount).toBe(9000);
    }
    expect(mockOrderRepository.confirmDelivery).toHaveBeenCalledWith({
      orderId: 'order-123',
      sellerId: 'seller-123',
      sellerAmount: 9000,
    });
  });

  it('returns error if order not found', async () => {
    mockOrderRepository.findById.mockResolvedValue(right(null));

    const input = {
      orderId: 'order-123',
      buyerId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('returns error if user is not the buyer', async () => {
    mockOrderRepository.findById.mockResolvedValue(
      right({
        id: 'order-123',
        buyerId: 'other-user-123',
        status: 'CONFIRMED',
      }),
    );

    const input = {
      orderId: 'order-123',
      buyerId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      const { UnauthorizedError } = await import('@/shared/core/errors');
      expect(result.value).toBeInstanceOf(UnauthorizedError);
    }
  });

  it('returns error if order is not SHIPPED', async () => {
    mockOrderRepository.findById.mockResolvedValue(
      right({
        id: 'order-123',
        buyerId: 'user-123',
        status: 'PENDING',
      }),
    );

    const input = {
      orderId: 'order-123',
      buyerId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidOrderStateError);
    }
  });

  it('returns error if order status is COMPLETED', async () => {
    mockOrderRepository.findById.mockResolvedValue(
      right({
        id: 'order-123',
        buyerId: 'user-123',
        status: 'COMPLETED',
      }),
    );

    const input = {
      orderId: 'order-123',
      buyerId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidOrderStateError);
    }
  });

  it('returns error if order status is CANCELLED', async () => {
    mockOrderRepository.findById.mockResolvedValue(
      right({
        id: 'order-123',
        buyerId: 'user-123',
        status: 'CANCELLED',
      }),
    );

    const input = {
      orderId: 'order-123',
      buyerId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidOrderStateError);
    }
  });
});
