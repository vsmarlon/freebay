import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { PrismaDisputeRepository } from '../repositories/dispute.repository';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';
import { DisputeResolutionExecutionService } from '../services/dispute-resolution-execution.service';

@Injectable()
export class ResolveDisputeUseCase {
  constructor(
    private prisma: PrismaService,
    private disputeRepo: PrismaDisputeRepository,
    private notificationService: NotificationService,
    private transitionPolicy: DisputeTransitionPolicy,
    private resolutionExecution: DisputeResolutionExecutionService,
  ) {}

  async execute(input: { disputeId: string; resolution: string; winner: 'BUYER' | 'SELLER' }): Promise<Either<AppError, { resolved: boolean }>> {
    const dispute = await this.disputeRepo.findById(input.disputeId);

    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    if (!this.transitionPolicy.canResolve(dispute.status)) {
      return left(new BadRequestError(`Dispute cannot be resolved while it is ${dispute.status}`));
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.dispute.update({
          where: { id: input.disputeId },
          data: {
            resolution: input.resolution,
            status: 'RESOLVED',
            resolvedAt: new Date(),
          },
        });

        if (input.winner === 'BUYER') {
          await this.resolutionExecution.resolveInFavorOfBuyer(tx, dispute);
        } else {
          await this.resolutionExecution.resolveInFavorOfSeller(tx, dispute);
        }
      });
    } catch {
      return left(new DatabaseError('Failed to resolve dispute'));
    }

    const buyerMsg = input.winner === 'BUYER' ? 'A disputa foi resolvida a seu favor' : 'A disputa foi resolvida a favor do vendedor';
    const sellerMsg = input.winner === 'SELLER' ? 'A disputa foi resolvida a seu favor' : 'A disputa foi resolvida a favor do comprador';
    await Promise.all([
      this.notificationService.notifyDispute(dispute.order.buyerId, dispute.id, buyerMsg),
      this.notificationService.notifyDispute(dispute.order.sellerId, dispute.id, sellerMsg),
    ]);

    return right({ resolved: true });
  }
}
