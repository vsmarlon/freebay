import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { TransferReconciliationTask } from './transfer-reconciliation.task';

describe('TransferReconciliationTask', () => {
  it('retries durable processing allocations through the payout service', async () => {
    const transactions = {
      reclaimStaleTransfer: jest.fn().mockResolvedValue(right({ count: 1 })),
      reclaimStaleReversal: jest.fn().mockResolvedValue(right({ count: 0 })),
      findTransferFailures: jest.fn().mockResolvedValue(right({ items: [{
        orderId: 'order-1',
        transferState: 'PROCESSING',
        reversalState: 'NOT_REQUIRED',
      }], hasMore: false, nextCursor: null })),
    };
    const payouts = {
      payoutForOrder: jest.fn().mockResolvedValue(undefined),
      reverseForOrder: jest.fn().mockResolvedValue(right(undefined)),
    };
    const module = await Test.createTestingModule({
      providers: [
        TransferReconciliationTask,
        { provide: TransactionDatabaseRepository, useValue: transactions },
        { provide: SellerPayoutService, useValue: payouts },
      ],
    }).compile();

    await module.get(TransferReconciliationTask).reconcile();

    expect(payouts.payoutForOrder).toHaveBeenCalledWith('order-1');
  });
});
