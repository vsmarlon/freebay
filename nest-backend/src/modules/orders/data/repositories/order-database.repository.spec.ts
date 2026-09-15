import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { decodeCursor } from '@/shared/core/pagination';
import { PrismaOrderRepository } from './order-database.repository';

describe('PrismaOrderRepository.findSellerSales', () => {
  it('uses the descending createdAt/id keyset and preserves tied timestamps', async () => {
    const findMany = jest.fn().mockResolvedValue([
      { id: 'order-2', createdAt: new Date('2026-09-12T00:00:00.000Z') },
    ]);
    const module = await Test.createTestingModule({
      providers: [
        PrismaOrderRepository,
        { provide: PrismaService, useValue: { order: { findMany } } },
      ],
    }).compile();
    const repository = module.get(PrismaOrderRepository);
    const createdAt = new Date('2026-09-12T00:00:00.000Z');

    const result = await repository.findSellerSales(
      'seller-1',
      { limit: 20 },
      undefined,
      {
        scope: 'seller-sales',
        sellerId: 'seller-1',
        status: null,
        createdAt,
        id: 'order-3',
      },
    );

    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: {
        sellerId: 'seller-1',
        OR: [
          { createdAt: { lt: createdAt } },
          { createdAt, id: { lt: 'order-3' } },
        ],
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 21,
    }));
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.hasMore).toBe(false);
      expect(result.value.nextCursor).toBeNull();
    }
  });

  it('returns an authoritative next cursor only after over-fetching one row', async () => {
    const findMany = jest.fn().mockResolvedValue([
      { id: 'order-1', createdAt: new Date('2026-09-13T00:00:00.000Z') },
      { id: 'order-2', createdAt: new Date('2026-09-12T00:00:00.000Z') },
    ]);
    const module = await Test.createTestingModule({
      providers: [
        PrismaOrderRepository,
        { provide: PrismaService, useValue: { order: { findMany } } },
      ],
    }).compile();
    const repository = module.get(PrismaOrderRepository);

    const result = await repository.findSellerSales(
      'seller-1',
      { limit: 1 },
      'SHIPPED',
      null,
    );

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.items).toHaveLength(1);
      expect(result.value.hasMore).toBe(true);
      expect(decodeCursor(result.value.nextCursor ?? undefined)).toEqual({
        scope: 'seller-sales',
        sellerId: 'seller-1',
        status: 'SHIPPED',
        createdAt: '2026-09-13T00:00:00.000Z',
        id: 'order-1',
      });
    }
  });
});
