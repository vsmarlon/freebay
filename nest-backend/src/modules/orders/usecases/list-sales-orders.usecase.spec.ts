import { Test } from '@nestjs/testing';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { ListSalesOrdersUseCase } from './list-sales-orders.usecase';
import { SalesOrdersQueryDTO } from '../dtos/order.dto';
import { BadRequestError } from '@/shared/core/errors';
import { encodeCursor } from '@/shared/core/pagination';
import { right } from '@/shared/core/either';

describe('ListSalesOrdersUseCase', () => {
  let sut: ListSalesOrdersUseCase;
  let findSellerSales: jest.Mock;

  beforeEach(async () => {
    findSellerSales = jest.fn();
    const module = await Test.createTestingModule({
      providers: [
        ListSalesOrdersUseCase,
        { provide: PrismaOrderRepository, useValue: { findSellerSales } },
      ],
    }).compile();
    sut = module.get(ListSalesOrdersUseCase);
  });

  const query = (values: { cursor?: string; limit?: number; status?: string } = {}) =>
    Object.assign(new SalesOrdersQueryDTO(), { limit: 2, ...values });

  it('scopes a valid page to the seller and status', async () => {
    const page = { items: [], hasMore: false, nextCursor: null };
    findSellerSales.mockResolvedValue(right(page));

    await expect(sut.execute('seller-1', query({ status: 'SHIPPED' })))
      .resolves.toEqual(right(page));
    expect(findSellerSales).toHaveBeenCalledWith('seller-1', { limit: 2 }, 'SHIPPED', null);
  });

  it.each([
    ['malformed cursor', 'not-a-cursor'],
    ['foreign seller cursor', encodeCursor({
      scope: 'seller-sales', sellerId: 'seller-2', status: 'ALL',
      createdAt: '2026-09-12T00:00:00.000Z', id: 'order-1',
    })],
    ['foreign status cursor', encodeCursor({
      scope: 'seller-sales', sellerId: 'seller-1', status: 'SHIPPED',
      createdAt: '2026-09-12T00:00:00.000Z', id: 'order-1',
    })],
  ])('rejects %s without querying', async (_name, cursor) => {
    const result = await sut.execute('seller-1', query({ cursor }));

    expect(result.isLeft()).toBe(true);
    expect(result.isLeft() && result.value).toBeInstanceOf(BadRequestError);
    expect(findSellerSales).not.toHaveBeenCalled();
  });

  it('rejects an invalid status', async () => {
    const result = await sut.execute('seller-1', query({ status: 'UNKNOWN' }));

    expect(result.isLeft()).toBe(true);
    expect(findSellerSales).not.toHaveBeenCalled();
  });

  it('passes a valid cursor and preserves pagination limit', async () => {
    const cursor = encodeCursor({
      scope: 'seller-sales', sellerId: 'seller-1', status: 'ALL',
      createdAt: '2026-09-12T00:00:00.000Z', id: 'order-1',
    });
    findSellerSales.mockResolvedValue(right({ items: [], hasMore: false, nextCursor: null }));

    await sut.execute('seller-1', query({ cursor, limit: 7 }));

    expect(findSellerSales).toHaveBeenCalledWith(
      'seller-1',
      { limit: 7 },
      undefined,
      expect.objectContaining({ sellerId: 'seller-1', status: null, id: 'order-1' }),
    );
  });
});
