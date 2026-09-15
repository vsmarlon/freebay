import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, DatabaseError } from '@/shared/core/errors';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { CursorPage, decodeCursor, clampLimit } from '@/shared/core/pagination';

export interface TransferFailureRow {
  transactionId: string;
  orderId: string;
  sellerId: string;
  sellerAmount: number;
  transferState: string;
  transferAttempts: number;
  transferProcessingAt: Date | null;
  transferId: string | null;
  transferLastError: string | null;
  reversalState: string;
  reversalAttempts: number;
  reversalProcessingAt: Date | null;
  reversalId: string | null;
  reversalLastError: string | null;
}

@Injectable()
export class ListTransferFailuresUseCase {
  constructor(private readonly transactions: TransactionDatabaseRepository) {}

  async execute(input: { cursor?: string; limit?: number } = {}): Promise<Either<AppError, CursorPage<TransferFailureRow>>> {
    const decoded = decodeCursor<{ updatedAt?: string; id?: string }>(input.cursor);
    if (input.cursor && (!decoded?.updatedAt || !decoded.id || Number.isNaN(Date.parse(decoded.updatedAt)))) {
      return left(new BadRequestError('Invalid transfer failure cursor'));
    }
    const repositoryCursor = decoded?.updatedAt && decoded.id
      ? { updatedAt: new Date(decoded.updatedAt), id: decoded.id }
      : null;
    const result = await this.transactions.findTransferFailures(
      repositoryCursor,
      clampLimit(input.limit),
    );
    if (result.isLeft()) return left(new DatabaseError('Failed to list transfer failures'));
    return right({ ...result.value, items: result.value.items.map((transaction) => ({
      transactionId: transaction.id,
      orderId: transaction.orderId,
      sellerId: transaction.order.sellerId,
      sellerAmount: transaction.sellerAmount,
      transferState: transaction.transferState,
      transferAttempts: transaction.transferAttempts,
      transferProcessingAt: transaction.transferProcessingAt,
      transferId: transaction.transferId,
      transferLastError: transaction.transferLastError,
      reversalState: transaction.reversalState,
      reversalAttempts: transaction.reversalAttempts,
      reversalProcessingAt: transaction.reversalProcessingAt,
      reversalId: transaction.reversalId,
      reversalLastError: transaction.reversalLastError,
    })) });
  }
}
