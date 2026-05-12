import { Test, TestingModule } from '@nestjs/testing';
import { CreateOrderUseCase, ConfirmDeliveryUseCase } from './order.usecase';
import { PrismaOrderRepository } from '../repositories/order.repository';
import { NotFoundError, InvalidOrderStateError } from '@/shared/core/errors';
import { PrismaClient } from '@prisma/client';

describe('CreateOrderUseCase', () => {
  let sut: CreateOrderUseCase;
  let mockOrderRepository: any;
  let mockPrisma: any;

  beforeEach(async () => {
    mockOrderRepository = {
      create: jest.fn(),
    };

    mockPrisma = {
      product: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'product-123',
          sellerId: 'seller-123',
          status: 'ACTIVE',
        }),
        update: jest.fn(),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      order: {
        create: jest.fn().mockResolvedValue({
          id: 'order-123',
          buyerId: 'buyer-123',
          sellerId: 'seller-123',
          productId: 'product-123',
          amount: 10000,
          platformFee: 1000,
          status: 'PENDING',
          createdAt: new Date(),
        }),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };
    mockPrisma.$transaction = jest.fn().mockImplementation(async (callback) => callback(mockPrisma));

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateOrderUseCase,
        { provide: PrismaOrderRepository, useValue: mockOrderRepository },
        { provide: PrismaClient, useValue: mockPrisma },
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
    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          buyer: { connect: { id: 'buyer-123' } },
          seller: { connect: { id: 'seller-123' } },
          platformFee: 1000,
        }),
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

    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          platformFee: 1500,
        }),
      }),
    );
  });
});

describe('ConfirmDeliveryUseCase', () => {
  let sut: ConfirmDeliveryUseCase;
  let mockOrderRepository: any;
  let mockPrisma: any;

  beforeEach(async () => {
    mockOrderRepository = {
      findById: jest.fn(),
      update: jest.fn(),
    };

    mockPrisma = {
      product: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      order: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConfirmDeliveryUseCase,
        { provide: PrismaOrderRepository, useValue: mockOrderRepository },
        { provide: PrismaClient, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<ConfirmDeliveryUseCase>(ConfirmDeliveryUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should confirm delivery when order is CONFIRMED or DELIVERED and user is buyer', async () => {
    mockOrderRepository.findById.mockResolvedValue({
      id: 'order-123',
      buyerId: 'user-123',
      sellerId: 'seller-123',
      status: 'CONFIRMED',
      sellerAmount: 9000,
    });
    mockPrisma.$transaction = jest.fn().mockImplementation(async (callback) => {
      return callback(mockPrisma);
    });
    mockPrisma.order = { update: jest.fn().mockResolvedValue({}) };
    mockPrisma.wallet = { 
      findUnique: jest.fn().mockResolvedValue({ id: 'wallet-1' }),
      update: jest.fn().mockResolvedValue({})
    };
    mockPrisma.transaction = { update: jest.fn().mockResolvedValue({}) };

    const input = {
      orderId: 'order-123',
      buyerId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.confirmed).toBe(true);
    }
  });

  it('should return error if order not found', async () => {
    mockOrderRepository.findById.mockResolvedValue(null);

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
    mockOrderRepository.findById.mockResolvedValue({
      id: 'order-123',
      buyerId: 'other-user-123',
      status: 'CONFIRMED',
    });

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
    mockOrderRepository.findById.mockResolvedValue({
      id: 'order-123',
      buyerId: 'user-123',
      status: 'PENDING',
    });

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
    mockOrderRepository.findById.mockResolvedValue({
      id: 'order-123',
      buyerId: 'user-123',
      status: 'COMPLETED',
    });

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
    mockOrderRepository.findById.mockResolvedValue({
      id: 'order-123',
      buyerId: 'user-123',
      status: 'CANCELLED',
    });

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
  let mockOrderRepository: any;
  let mockPrisma: any;

  beforeEach(async () => {
    mockOrderRepository = {
      create: jest.fn(),
    };

    mockPrisma = {
      product: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'product-123',
          sellerId: 'seller-123',
          status: 'ACTIVE',
        }),
        update: jest.fn(),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      order: {
        create: jest.fn().mockResolvedValue({
          id: 'order-123',
          buyerId: 'buyer-123',
          sellerId: 'seller-123',
          productId: 'product-123',
          amount: 10000,
          platformFee: 1000,
          status: 'PENDING',
          createdAt: new Date(),
        }),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };
    mockPrisma.$transaction = jest.fn().mockImplementation(async (callback) => callback(mockPrisma));

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateOrderUseCase,
        { provide: PrismaOrderRepository, useValue: mockOrderRepository },
        { provide: PrismaClient, useValue: mockPrisma },
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

    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          platformFee: 500,
        }),
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

    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          platformFee: 2000,
        }),
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

    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          platformFee: 1000,
        }),
      }),
    );
  });
});
