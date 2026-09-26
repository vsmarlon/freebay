import { Test } from '@nestjs/testing';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { GetOrderUseCase } from './get-order.usecase';
import { ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';
import { UserRole } from '@prisma/client';

describe('GetOrderUseCase', () => {
  let sut: GetOrderUseCase;
  let findById: jest.Mock;

  beforeEach(async () => {
    findById = jest.fn();
    const module = await Test.createTestingModule({
      providers: [
        GetOrderUseCase,
        { provide: PrismaOrderRepository, useValue: { findById } },
      ],
    }).compile();
    sut = module.get(GetOrderUseCase);
  });

  const order = { buyerId: 'buyer-1', sellerId: 'seller-1' };

  it.each([
    ['buyer', { userId: 'buyer-1', role: UserRole.USER }],
    ['seller', { userId: 'seller-1', role: UserRole.USER }],
    ['admin', { userId: 'admin-1', role: UserRole.ADMIN }],
  ] as const)('allows the %s', async (_role, user) => {
    findById.mockResolvedValue(right(order));

    await expect(sut.execute('order-1', user)).resolves.toEqual(right({ order }));
  });

  it('rejects an outsider', async () => {
    findById.mockResolvedValue(right(order));

    const result = await sut.execute('order-1', { userId: 'other-1', role: UserRole.USER });

    expect(result.isLeft()).toBe(true);
    expect(result.isLeft() && result.value).toBeInstanceOf(ForbiddenError);
  });

  it('rejects a missing order', async () => {
    findById.mockResolvedValue(right(null));

    const result = await sut.execute('missing', { userId: 'buyer-1', role: 'USER' });

    expect(result.isLeft()).toBe(true);
    expect(result.isLeft() && result.value).toBeInstanceOf(NotFoundError);
  });
});
