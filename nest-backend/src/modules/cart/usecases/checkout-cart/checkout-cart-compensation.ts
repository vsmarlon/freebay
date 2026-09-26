import { Logger } from "@nestjs/common";
import { PaymentGroupStatus, Prisma } from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { CartDatabaseRepository } from "../../data/repositories/cart-database.repository";
import { PaymentGroupDatabaseRepository } from "@/modules/payments/data/repositories/payment-group-database.repository";

export class CheckoutCartCompensation {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cartRepository: CartDatabaseRepository,
    private readonly paymentGroupRepository: PaymentGroupDatabaseRepository,
    private readonly logger: Logger,
  ) {}

  async compensate(groupId: string, orders: Array<{ orderId: string; productId: string }>): Promise<void> {
    try {
      await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
        for (const entry of orders) {
          await this.cartRepository.restoreOrderReservation(entry.orderId, entry.productId, tx);
        }
        await this.paymentGroupRepository.markTerminal(groupId, PaymentGroupStatus.FAILED, tx);
      });
    } catch (error) {
      this.logger.error(`Failed to compensate cart checkout group ${groupId}: ${error instanceof Error ? error.message : String(error)}. The checkout expiry job will reclaim it.`);
    }
  }
}
