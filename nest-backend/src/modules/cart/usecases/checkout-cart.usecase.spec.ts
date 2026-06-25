import { Test, TestingModule } from '@nestjs/testing';
import { CheckoutCartUseCase } from './checkout-cart.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaCartRepository } from '../repositories/cart.repository';
import { CreatePixPaymentUseCase } from '@/modules/payments/usecases/payment.usecase';
import { BadRequestError } from '@/shared/core/errors';
import { right, left } from '@/shared/core/either';

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
  },
  product: {
    findUnique: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
  },
  order: {
    create: jest.fn(),
    delete: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockCartRepository = {
  getUserCart: jest.fn(),
  clear: jest.fn(),
};

const mockPixUseCase = {
  execute: jest.fn(),
};

describe('CheckoutCartUseCase', () => {
  let sut: CheckoutCartUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CheckoutCartUseCase,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: PrismaCartRepository, useValue: mockCartRepository },
        { provide: CreatePixPaymentUseCase, useValue: mockPixUseCase },
      ],
    }).compile();

    sut = module.get<CheckoutCartUseCase>(CheckoutCartUseCase);
    jest.clearAllMocks();
  });

  const userData = { displayName: 'John', email: 'john@test.com', cpf: '12345678901' };
  const productData = { id: 'prod-1', title: 'Test Product', price: 10000, sellerId: 'seller-1', status: 'ACTIVE' as const };
  const cartItem = { id: 'item-1', productId: 'prod-1', quantity: 2, product: productData };

  it('should return error if user has no CPF', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ displayName: 'John', email: 'john@test.com', cpf: null });
    const result = await sut.execute({ userId: 'user-1' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return error if cart is empty', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(userData);
    mockCartRepository.getUserCart.mockResolvedValue([]);
    const result = await sut.execute({ userId: 'user-1' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return error if buying own product', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(userData);
    mockCartRepository.getUserCart.mockResolvedValue([{ ...cartItem, product: { ...productData, sellerId: 'user-1' } }]);
    const result = await sut.execute({ userId: 'user-1' });
    expect(result.isLeft()).toBe(true);
  });

  it('should return error if product is unavailable', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(userData);
    mockCartRepository.getUserCart.mockResolvedValue([{ ...cartItem, product: { ...productData, status: 'SOLD' } }]);
    const result = await sut.execute({ userId: 'user-1' });
    expect(result.isLeft()).toBe(true);
  });

  it('should checkout successfully', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(userData);
    mockCartRepository.getUserCart.mockResolvedValue([cartItem]);
    mockPrisma.$transaction.mockImplementation(async (cb) => {
      const tx = {
        product: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
        order: {
          create: jest.fn().mockResolvedValue({
            id: 'order-1', amount: 20000, platformFee: 2000, sellerAmount: 18000,
          }),
        },
      };
      return cb(tx);
    });
    mockPixUseCase.execute.mockResolvedValue(right({
      orderId: 'order-1', pixQrCode: 'qr-code', pixImage: 'image', expiresAt: new Date(),
    }));
    mockCartRepository.clear.mockResolvedValue(undefined);

    const result = await sut.execute({ userId: 'user-1' });
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.totalOrders).toBe(1);
      expect(result.value.totalAmount).toBe(20000);
    }
  });

  it('should rollback order if PIX payment fails', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(userData);
    mockCartRepository.getUserCart.mockResolvedValue([cartItem]);

    let orderCreated = false;
    mockPrisma.$transaction.mockImplementation(async (cb) => {
      if (!orderCreated) {
        orderCreated = true;
        const tx = {
          product: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
          order: { create: jest.fn().mockResolvedValue({ id: 'order-1' }) },
        };
        return cb(tx);
      }
      const tx = {
        order: { delete: jest.fn().mockResolvedValue({}) },
        product: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      };
      return cb(tx);
    });
    mockPixUseCase.execute.mockResolvedValue(left(new BadRequestError('Payment failed')));

    const result = await sut.execute({ userId: 'user-1' });
    expect(result.isLeft()).toBe(true);
  });

  it('should throw if product was concurrently reserved by another checkout', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(userData);
    mockCartRepository.getUserCart.mockResolvedValue([cartItem]);
    mockPrisma.$transaction.mockImplementation(async (cb) => {
      const tx = {
        product: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
        order: { create: jest.fn() },
      };
      return cb(tx);
    });

    await expect(sut.execute({ userId: 'user-1' })).rejects.toBeInstanceOf(BadRequestError);
  });
});
