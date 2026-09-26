import { Injectable } from '@nestjs/common';
import { DisputeStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { PrismaDisputeRepository } from '../data/repositories/dispute-database.repository';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';
import { DisputeResolutionExecutionService } from '../services/dispute-resolution-execution.service';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { DisputeWinner } from '../dispute.constants';

@Injectable()
export class ResolveDisputeUseCase {
  constructor(
    private prisma: PrismaService,
    private disputeRepo: PrismaDisputeRepository,
    private notificationService: NotificationService,
    private transitionPolicy: DisputeTransitionPolicy,
    private resolutionExecution: DisputeResolutionExecutionService,
    private payoutService: SellerPayoutService,
  ) {}

  async execute(input: {
    disputeId: string;
    resolution: string;
    winner: 'BUYER' | 'SELLER';
    resolvedById?: string;
  }): Promise<Either<AppError, void>> {
    const disputeResult = await this.disputeRepo.findById(input.disputeId);
    if (disputeResult.isLeft()) return left(disputeResult.value);

    const dispute = disputeResult.value;
    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    if (!this.transitionPolicy.canResolve(dispute.status)) {
      return left(new BadRequestError(`Dispute cannot be resolved while it is ${dispute.status}`));
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.dispute.updateMany({
          where: { id: input.disputeId, status: { notIn: [DisputeStatus.RESOLVED, DisputeStatus.CANCELLED] } },
          data: {
            resolution: input.resolution,
            resolvedById: input.resolvedById ?? null,
            status: DisputeStatus.RESOLVED,
            resolvedAt: new Date(),
          },
        });
        if (claimed.count === 0) {
          throw new Error('DISPUTE_NOT_RESOLVABLE');
        }

        if (input.winner === DisputeWinner.BUYER) {
          await this.resolutionExecution.resolveInFavorOfBuyer(tx, dispute);
        } else {
          await this.resolutionExecution.resolveInFavorOfSeller(tx, dispute);
        }
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'DISPUTE_NOT_RESOLVABLE') {
        return left(new BadRequestError('Dispute cannot be resolved while it is not open'));
      }
      return left(new DatabaseError('Failed to resolve dispute'));
    }

    if (input.winner === DisputeWinner.SELLER) {
      await this.payoutService.payoutForOrder(dispute.orderId);
    }

    const buyerMsg = input.winner === DisputeWinner.BUYER ? 'A disputa foi resolvida a seu favor' : 'A disputa foi resolvida a favor do vendedor';
    const sellerMsg = input.winner === DisputeWinner.SELLER ? 'A disputa foi resolvida a seu favor' : 'A disputa foi resolvida a favor do comprador';
    await Promise.all([
      this.notificationService.notifyDispute(dispute.order.buyerId, dispute.id, buyerMsg),
      this.notificationService.notifyDispute(dispute.order.sellerId, dispute.id, sellerMsg),
    ]);

    return right(undefined);
  }
}
