import { Injectable, Logger } from '@nestjs/common';
import { ReversalState, TransferDeliveryState } from '@prisma/client';
import { WalletEntryReason } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { StripeProvider } from '../providers/stripe-provider';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { ConnectAccountDatabaseRepository } from '../data/repositories/connect-account-database.repository';

@Injectable()
export class SellerPayoutService {
  private readonly logger = new Logger(SellerPayoutService.name);

  constructor(
    private readonly transactionRepo: TransactionDatabaseRepository,
    private readonly connectRepo: ConnectAccountDatabaseRepository,
    private readonly stripe: StripeProvider,
    private readonly prisma: PrismaService,
  ) {}

  async payoutForOrder(orderId: string): Promise<void> {
    const found = await this.transactionRepo.findByOrderId(orderId);
    if (found.isLeft() || !found.value) return;
    const transaction = found.value;
    if (transaction.transferState === TransferDeliveryState.SUCCEEDED || transaction.transferId) return;
    if (!transaction.chargeId) return;

    const account = await this.connectRepo.findByUserId(transaction.order.sellerId);
    if (account.isLeft() || !account.value) return;

    const now = new Date();
    const claimed = await this.transactionRepo.claimTransfer(transaction.orderId, now);
    if (claimed.isLeft() || claimed.value.count === 0) return;

    const refreshed = await this.stripe.refreshConnectAccount(account.value.stripeAccountId);
    if (refreshed.isLeft() || refreshed.value.status !== 'transfer-ready') {
      await this.transactionRepo.markTransferFailure(
        transaction.id,
        this.failureState(refreshed.isLeft() ? refreshed.value : undefined),
        refreshed.isLeft() ? refreshed.value.message : 'Seller account is not transfer-ready',
      );
      return;
    }
    const saved = await this.connectRepo.upsertFromSnapshot(transaction.order.sellerId, refreshed.value);
    if (saved.isLeft()) {
      await this.transactionRepo.markTransferFailure(transaction.id, this.failureState(saved.value), saved.value.message);
      return;
    }

    const transferGroup = transaction.paymentGroupId
      ? `freebay:payment-group:${transaction.paymentGroupId}`
      : `freebay:order:${orderId}`;
    const reconciliation = await this.stripe.findTransfer({
      transferId: transaction.transferId ?? undefined,
      transferGroup,
      orderId,
      transactionId: transaction.id,
      paymentGroupId: transaction.paymentGroupId ?? undefined,
      destination: refreshed.value.stripeAccountId,
      idempotencyKey: transaction.transferIdempotencyKey,
    });
    if (reconciliation.isLeft()) return;
    let providerId = reconciliation.value?.providerId;
    if (!providerId) {
      const created = await this.stripe.createTransfer({
      amount: transaction.sellerAmount,
      currency: refreshed.value.defaultCurrency,
      destination: refreshed.value.stripeAccountId,
      sourceTransaction: transaction.chargeId,
      orderId,
      transactionId: transaction.id,
      paymentGroupId: transaction.paymentGroupId ?? undefined,
      transferGroup,
      idempotencyKey: transaction.transferIdempotencyKey,
      });
      if (created.isLeft()) {
        await this.transactionRepo.markTransferFailure(transaction.id, this.failureState(created.value), created.value.message);
        return;
      }
      providerId = created.value;
    }

    await this.prisma.$transaction(async (tx) => {
      const finalized = await this.transactionRepo.finalizeTransfer(transaction.id, providerId, tx);
      if (finalized.isLeft() || finalized.value.count === 0) return;
      await applyWalletDelta(tx, transaction.order.sellerId, { availableBalance: -transaction.sellerAmount }, {
        reason: WalletEntryReason.PAYOUT,
        orderId,
        transferId: providerId,
      });
    });
  }

  async reverseForOrder(orderId: string): Promise<Either<AppError, void>> {
    const found = await this.transactionRepo.findByOrderId(orderId);
    if (found.isLeft()) return left(found.value);
    if (!found.value || !found.value.transferId) return right(undefined);
    const transaction = found.value;
    const transferId = transaction.transferId;
    if (!transferId) return right(undefined);
    if (transaction.reversalState === ReversalState.SUCCEEDED) return right(undefined);

    const claimed = await this.transactionRepo.claimReversal(orderId, new Date());
    if (claimed.isLeft()) return left(claimed.value);
    if (claimed.value.count === 0) return right(undefined);

    const existing = await this.stripe.findReversal({
      transferId,
      reversalId: transaction.reversalId ?? undefined,
      orderId,
      transactionId: transaction.id,
      idempotencyKey: transaction.reversalIdempotencyKey,
    });
    if (existing.isLeft()) return left(existing.value);
    if (existing.value) {
      const finalized = await this.transactionRepo.finalizeReversal(transaction.id, existing.value);
      return finalized.isLeft() ? left(finalized.value) : right(undefined);
    }

    const reversed = await this.stripe.reverseTransfer(
      transferId,
      transaction.sellerAmount,
      orderId,
      transaction.id,
      transaction.reversalIdempotencyKey,
    );
    if (reversed.isLeft()) {
      await this.transactionRepo.markReversalFailure(transaction.id, this.failureReversalState(reversed.value), reversed.value.message);
      return left(reversed.value);
    }
    const finalized = await this.transactionRepo.finalizeReversal(transaction.id, reversed.value);
    if (finalized.isLeft()) return left(finalized.value);
    this.logger.log(`Reversed transfer ${transaction.transferId} for order ${orderId}`);
    return right(undefined);
  }

  private failureState(error: AppError | undefined): Extract<TransferDeliveryState, 'RETRYABLE' | 'TERMINAL'> {
    if (!error) return TransferDeliveryState.RETRYABLE;
    return [400, 401, 403, 404, 422].includes(error.statusCode)
      ? TransferDeliveryState.TERMINAL
      : TransferDeliveryState.RETRYABLE;
  }

  private failureReversalState(error: AppError | undefined): Extract<ReversalState, 'RETRYABLE' | 'TERMINAL'> {
    if (!error) return ReversalState.RETRYABLE;
    return [400, 401, 403, 404, 422].includes(error.statusCode)
      ? ReversalState.TERMINAL
      : ReversalState.RETRYABLE;
  }
}
