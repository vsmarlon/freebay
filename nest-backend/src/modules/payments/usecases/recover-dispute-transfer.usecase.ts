import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { SellerPayoutService } from '../services/seller-payout.service';

@Injectable()
export class RecoverDisputeTransferUseCase {
  constructor(
    private readonly transactions: TransactionDatabaseRepository,
    private readonly payouts: SellerPayoutService,
  ) {}

  async execute(chargeId: string): Promise<Either<AppError, void>> {
    const transaction = await this.transactions.findByChargeId(chargeId);
    if (transaction.isLeft()) return left(transaction.value);
    if (!transaction.value?.transferId) return right(undefined);
    return this.payouts.reverseForOrder(transaction.value.orderId);
  }
}
