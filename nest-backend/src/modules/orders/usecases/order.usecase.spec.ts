import { Test, TestingModule } from '@nestjs/testing';
import { CreateOrderUseCase } from './create-order.usecase';
import { ConfirmDeliveryUseCase } from './confirm-delivery.usecase';
import { OrderRepository } from '../domain/repositories/order.repository';
import { NotFoundError, InvalidOrderStateError } from '@/shared/core/errors';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { right } from '@/shared/core/either';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';

describe('CreateOrderUseCase', () => {
  let sut: CreateOrderUseCase;
  let mockOrderRepository: { createOrderWithReservation: jest.Mock };

  beforeEach(async () => {
    mockOrderRepository = {
      createOrderWithReservation: jest.fn().mockResolvedValue(right({ id: 'order-123' })),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateOrderUseCase,
        { provide: OrderRepository, useValue: mockOrderRepository },
        { provide: NotificationService, useValue: { create: jest.fn() } },
      ],
    }).compile();

    sut = module.get<CreateOrderUseCase>(CreateOrderUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should create a new order with correct platform fee', async () => {
    const input = {
      buyerId: 'buyer-123',
      sellerId: 'seller-123',
      productId: 'product-123',
      amount: 10000,
      platformFeePercent: 10,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.amount).toBe(10000);
      expect(result.value.status).toBe('PENDING');
    }
    expect(mockOrderRepository.createOrderWithReservation).toHaveBeenCalledWith(
      expect.objectContaining({
        buyerId: 'buyer-123',
        sellerId: 'seller-123',
        productId: 'product-123',
        amount: 10000,
        platformFee: 1000,
        sellerAmount: 9000,
      }),
    );
  });

  it('should calculate platform fee correctly for 15%', async () => {
    const input = {
      buyerId: 'buyer-123',
      sellerId: 'seller-123',
      productId: 'product-123',
      amount: 10000,
      platformFeePercent: 15,
    };

    await sut.execute(input);

    expect(mockOrderRepository.createOrderWithReservation).toHaveBeenCalledWith(
      expect.objectContaining({
        platformFee: 1500,
        sellerAmount: 8500,
      }),
    );
  });
});

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
        { provide: OrderRepository, useValue: mockOrderRepository },
        { provide: SellerPayoutService, useValue: { payoutForOrder: jest.fn() } },
      ],
    }).compile();

    sut = module.get<ConfirmDeliveryUseCase>(ConfirmDeliveryUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should confirm delivery when order is CONFIRMED or DELIVERED and user is buyer', async () => {
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

  it('should return error if order not found', async () => {
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

  it('should return error if user is not the buyer', async () => {
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

  it('should return error if order is not SHIPPED', async () => {
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

  it('should return error if order status is COMPLETED', async () => {
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

  it('should return error if order status is CANCELLED', async () => {
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

describe('CreateOrderUseCase - platform fee calculations', () => {
  let sut: CreateOrderUseCase;
  let mockOrderRepository: { createOrderWithReservation: jest.Mock };

  beforeEach(async () => {
    mockOrderRepository = {
      createOrderWithReservation: jest.fn().mockResolvedValue(right({ id: 'order-123' })),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateOrderUseCase,
        { provide: OrderRepository, useValue: mockOrderRepository },
        { provide: NotificationService, useValue: { create: jest.fn() } },
      ],
    }).compile();

    sut = module.get<CreateOrderUseCase>(CreateOrderUseCase);
  });

  it('should calculate platform fee correctly for 5%', async () => {
    const input = {
      buyerId: 'buyer-123',
      sellerId: 'seller-123',
      productId: 'product-123',
      amount: 10000,
      platformFeePercent: 5,
    };

    await sut.execute(input);

    expect(mockOrderRepository.createOrderWithReservation).toHaveBeenCalledWith(
      expect.objectContaining({
        platformFee: 500,
        sellerAmount: 9500,
      }),
    );
  });

  it('should calculate platform fee correctly for 20%', async () => {
    const input = {
      buyerId: 'buyer-123',
      sellerId: 'seller-123',
      productId: 'product-123',
      amount: 10000,
      platformFeePercent: 20,
    };

    await sut.execute(input);

    expect(mockOrderRepository.createOrderWithReservation).toHaveBeenCalledWith(
      expect.objectContaining({
        platformFee: 2000,
        sellerAmount: 8000,
      }),
    );
  });

  it('should round platform fee to nearest integer', async () => {
    const input = {
      buyerId: 'buyer-123',
      sellerId: 'seller-123',
      productId: 'product-123',
      amount: 10001,
      platformFeePercent: 10,
    };

    await sut.execute(input);

    expect(mockOrderRepository.createOrderWithReservation).toHaveBeenCalledWith(
      expect.objectContaining({
        platformFee: 1000,
      }),
    );
  });
});
