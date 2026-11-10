import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { encodeCursor } from '@/shared/core/pagination';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { ListTransferFailuresUseCase } from './list-transfer-failures.usecase';

describe('ListTransferFailuresUseCase', () => {
  it('returns operator-visible transfer and reversal state', async () => {
    const repository = {
      findTransferFailures: jest.fn().mockResolvedValue(right({ items: [{
        id: 'transaction-1',
        orderId: 'order-1',
        sellerAmount: 9000,
        transferState: 'RETRYABLE',
        transferAttempts: 2,
        transferProcessingAt: null,
        transferId: null,
        transferLastError: 'timeout',
        reversalState: 'NOT_REQUIRED',
        reversalAttempts: 0,
        reversalProcessingAt: null,
        reversalId: null,
        reversalLastError: null,
        order: { sellerId: 'seller-1' },
      }], hasMore: true, nextCursor: 'next'})),
    };
    const module = await Test.createTestingModule({
      providers: [
        ListTransferFailuresUseCase,
        { provide: TransactionDatabaseRepository, useValue: repository },
      ],
    }).compile();

    const result = await module.get(ListTransferFailuresUseCase).execute();

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.items[0]).toMatchObject({
        transactionId: 'transaction-1',
        sellerId: 'seller-1',
        transferLastError: 'timeout',
      });
    }
  });

  it('passes a valid opaque cursor and bounded limit to the repository', async () => {
    const repository = {
      findTransferFailures: jest.fn().mockResolvedValue(right({ items: [], hasMore: false, nextCursor: null })),
    };
    const module = await Test.createTestingModule({
      providers: [
        ListTransferFailuresUseCase,
        { provide: TransactionDatabaseRepository, useValue: repository },
      ],
    }).compile();
    const cursor = encodeCursor({ updatedAt: '2026-09-14T00:00:00.000Z', id: 'transaction-2' });

    const result = await module.get(ListTransferFailuresUseCase).execute({ cursor, limit: 500 });

    expect(result.isRight()).toBe(true);
    expect(repository.findTransferFailures).toHaveBeenCalledWith(
      { updatedAt: new Date('2026-09-14T00:00:00.000Z'), id: 'transaction-2' },
      50,
    );
  });

  it('rejects a malformed cursor before touching the database', async () => {
    const repository = { findTransferFailures: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        ListTransferFailuresUseCase,
        { provide: TransactionDatabaseRepository, useValue: repository },
      ],
    }).compile();

    const result = await module.get(ListTransferFailuresUseCase).execute({ cursor: 'bad' });

    expect(result.isLeft()).toBe(true);
    expect(repository.findTransferFailures).not.toHaveBeenCalled();
  });
});
