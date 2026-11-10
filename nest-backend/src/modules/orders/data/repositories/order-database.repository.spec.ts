import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { decodeCursor } from '@/shared/core/pagination';
import { BadRequestError } from '@/shared/core/errors';
import { OrderDatabaseRepository } from './order-database.repository';

describe('OrderDatabaseRepository.findSellerSales', () => {
  it('uses the descending createdAt/id keyset and preserves tied timestamps', async () => {
    const findMany = jest.fn().mockResolvedValue([
      { id: 'order-2', createdAt: new Date('2026-09-12T00:00:00.000Z') },
    ]);
    const module = await Test.createTestingModule({
      providers: [
        OrderDatabaseRepository,
        { provide: PrismaService, useValue: { order: { findMany } } },
      ],
    }).compile();
    const repository = module.get(OrderDatabaseRepository);
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
        OrderDatabaseRepository,
        { provide: PrismaService, useValue: { order: { findMany } } },
      ],
    }).compile();
    const repository = module.get(OrderDatabaseRepository);

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

describe('OrderDatabaseRepository.claimCancellation', () => {
  it('recognizes retries by durable operation ownership, not by the prior reason string', async () => {
    const updateMany = jest.fn()
      .mockResolvedValueOnce({ count: 1 })
      .mockResolvedValueOnce({ count: 0 })
      .mockResolvedValueOnce({ count: 0 });
    const findFirst = jest.fn()
      .mockResolvedValueOnce({ id: 'order-1' })
      .mockResolvedValueOnce(null);
    const module = await Test.createTestingModule({
      providers: [
        OrderDatabaseRepository,
        { provide: PrismaService, useValue: { order: { findFirst, updateMany } } },
      ],
    }).compile();
    const repository = module.get(OrderDatabaseRepository);

    const initial = await repository.claimCancellation(
      'order-1', 'CONFIRMED', 'Original reason', { refundOperationId: 'refund-op-1' },
    );
    const retry = await repository.claimCancellation(
      'order-1', 'CONFIRMED', 'Changed reason', { refundOperationId: 'refund-op-1' },
    );
    const unrelated = await repository.claimCancellation(
      'order-1', 'CONFIRMED', 'Unrelated request', { refundOperationId: 'refund-op-2' },
    );

    expect(initial.isRight() && initial.value).toBe(true);
    expect(retry.isRight() && retry.value).toBe(true);
    expect(unrelated.isRight() && unrelated.value).toBe(false);
    expect(findFirst).toHaveBeenNthCalledWith(1, expect.objectContaining({
      where: expect.objectContaining({
        transaction: { is: { refundOperationId: 'refund-op-1' } },
      }),
    }));
    expect(findFirst).toHaveBeenNthCalledWith(2, expect.objectContaining({
      where: expect.objectContaining({
        transaction: { is: { refundOperationId: 'refund-op-2' } },
      }),
    }));
  });
});

describe('OrderDatabaseRepository.findStaleUnpaidOrders', () => {
  it('only selects PENDING orders that have no transaction older than the cutoff', async () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const module = await Test.createTestingModule({
      providers: [
        OrderDatabaseRepository,
        { provide: PrismaService, useValue: { order: { findMany } } },
      ],
    }).compile();
    const repository = module.get(OrderDatabaseRepository);
    const cutoff = new Date('2026-11-06T11:30:00.000Z');

    const result = await repository.findStaleUnpaidOrders(cutoff);

    expect(findMany).toHaveBeenCalledWith({
      where: { status: 'PENDING', transaction: { is: null }, createdAt: { lt: cutoff } },
      select: { id: true, productId: true, quantity: true },
    });
    expect(result.isRight()).toBe(true);
  });
});

describe('OrderDatabaseRepository.claimCheckoutAbandoned', () => {
  const buildRepository = async (updateMany: jest.Mock) => {
    const module = await Test.createTestingModule({
      providers: [
        OrderDatabaseRepository,
        { provide: PrismaService, useValue: { order: { updateMany } } },
      ],
    }).compile();
    return module.get(OrderDatabaseRepository);
  };

  it('claims only a PENDING order that still has no transaction', async () => {
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const repository = await buildRepository(updateMany);

    const claimed = await repository.claimCheckoutAbandoned('order-1');

    expect(updateMany).toHaveBeenCalledWith({
      where: { id: 'order-1', status: 'PENDING', transaction: { is: null } },
      data: { status: 'CANCELLED', cancellationReason: 'CHECKOUT_ABANDONED' },
    });
    expect(claimed.isRight() && claimed.value).toBe(true);
  });

  it('reports no claim when the order moved on', async () => {
    const updateMany = jest.fn().mockResolvedValue({ count: 0 });
    const repository = await buildRepository(updateMany);

    const claimed = await repository.claimCheckoutAbandoned('order-1');

    expect(claimed.isRight() && claimed.value).toBe(false);
  });
});

describe('OrderDatabaseRepository.createOrderWithReservation', () => {
  it('rejects a new order when the buyer already holds the unpaid-order cap', async () => {
    const count = jest.fn().mockResolvedValue(10);
    const module = await Test.createTestingModule({
      providers: [
        OrderDatabaseRepository,
        {
          provide: PrismaService,
          useValue: {
            $transaction: jest.fn(async (callback: (tx: unknown) => unknown) =>
              callback({ order: { count } }),
            ),
          },
        },
      ],
    }).compile();
    const repository = module.get(OrderDatabaseRepository);

    const result = await repository.createOrderWithReservation({
      buyerId: 'buyer-1',
      productId: 'product-1',
    });

    expect(count).toHaveBeenCalledWith({
      where: { buyerId: 'buyer-1', status: 'PENDING', transaction: { is: null } },
    });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
      expect(result.value.message).toBe('Muitos pedidos aguardando pagamento');
    }
  });
});
