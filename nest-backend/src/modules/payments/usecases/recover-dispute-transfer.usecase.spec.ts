import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { SellerPayoutService } from '../services/seller-payout.service';
import { RecoverDisputeTransferUseCase } from './recover-dispute-transfer.usecase';

describe('RecoverDisputeTransferUseCase', () => {
  it('reverses only an allocated charge transfer', async () => {
    const transactions = {
      findByChargeId: jest.fn().mockResolvedValue(right({
        transferId: 'tr_1',
        orderId: 'order-1',
      })),
    };
    const payouts = { reverseForOrder: jest.fn().mockResolvedValue(right(undefined)) };
    const module = await Test.createTestingModule({
      providers: [
        RecoverDisputeTransferUseCase,
        { provide: TransactionDatabaseRepository, useValue: transactions },
        { provide: SellerPayoutService, useValue: payouts },
      ],
    }).compile();

    const result = await module.get(RecoverDisputeTransferUseCase).execute('ch_1');

    expect(result.isRight()).toBe(true);
    expect(payouts.reverseForOrder).toHaveBeenCalledWith('order-1');
  });
});
