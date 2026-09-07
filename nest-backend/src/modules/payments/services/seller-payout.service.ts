import { Injectable, Logger } from '@nestjs/common';
import { WalletEntryReason } from '@prisma/client';
import { isLeft } from '@/shared/core/either';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { StripeProvider } from '../providers/stripe-provider';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { ConnectAccountRepository } from '../domain/repositories/connect-account.repository';

@Injectable()
export class SellerPayoutService {
  private readonly logger = new Logger(SellerPayoutService.name);

  constructor(
    private readonly transactionRepo: TransactionRepository,
    private readonly connectRepo: ConnectAccountRepository,
    private readonly stripe: StripeProvider,
    private readonly prisma: PrismaService,
  ) {}

  async payoutForOrder(orderId: string): Promise<void> {
    const found = await this.transactionRepo.findByOrderId(orderId);
    if (isLeft(found) || !found.value) return;

    const transaction = found.value;
    if (transaction.transferId) return;

    if (!transaction.chargeId) {
      this.logger.warn(`Order ${orderId} has no charge id yet; payout deferred`);
      return;
    }

    const account = await this.connectRepo.findByUserId(transaction.order.sellerId);
    if (isLeft(account)) return;
    if (!account.value || !account.value.transfersEnabled) {
      this.logger.warn(
        `Seller ${transaction.order.sellerId} cannot receive transfers yet; order ${orderId} stays owed`,
      );
      return;
    }

    const transfer = await this.stripe.createTransfer({
      amount: transaction.sellerAmount,
      currency: account.value.defaultCurrency,
      destination: account.value.stripeAccountId,
      sourceTransaction: transaction.chargeId,
      orderId,
    });
    if (isLeft(transfer)) {
      this.logger.error(`Transfer failed for order ${orderId}: ${transfer.value.message}`);
      return;
    }

    await this.prisma.$transaction(async (tx) => {
      const claimed = await this.transactionRepo.claimTransfer(orderId, transfer.value, tx);
      if (isLeft(claimed) || claimed.value.count === 0) return;

      await applyWalletDelta(
        tx,
        transaction.order.sellerId,
        { availableBalance: -transaction.sellerAmount },
        { reason: WalletEntryReason.PAYOUT, orderId, transferId: transfer.value },
      );
    });

    this.logger.log(`Transferred ${transaction.sellerAmount} for order ${orderId}`);
  }

  async reverseForOrder(orderId: string): Promise<void> {
    const found = await this.transactionRepo.findByOrderId(orderId);
    if (isLeft(found) || !found.value) return;

    const transaction = found.value;
    if (!transaction.transferId) return;

    const reversed = await this.stripe.reverseTransfer(
      transaction.transferId,
      transaction.sellerAmount,
      orderId,
    );
    if (isLeft(reversed)) {
      this.logger.error(`Transfer reversal failed for order ${orderId}: ${reversed.value.message}`);
      return;
    }

    this.logger.log(`Reversed transfer ${transaction.transferId} for order ${orderId}`);
  }
}
