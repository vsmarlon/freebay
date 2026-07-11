import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, BadRequestError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { DisputeRepository } from '../domain/repositories/dispute.repository';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';

@Injectable()
export class WithdrawDisputeUseCase {
  constructor(
    private prisma: PrismaService,
    private disputeRepo: DisputeRepository,
    private transitionPolicy: DisputeTransitionPolicy,
    private notificationService: NotificationService,
  ) {}

  async execute(input: { disputeId: string; userId: string }): Promise<Either<AppError, void>> {
    const disputeResult = await this.disputeRepo.findById(input.disputeId);
    if (disputeResult.isLeft()) return left(disputeResult.value);

    const dispute = disputeResult.value;
    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    if (!this.transitionPolicy.isOpener(dispute, input.userId)) {
      return left(new UnauthorizedError('Only the dispute opener may withdraw it'));
    }

    if (!this.transitionPolicy.canWithdraw(dispute.status)) {
      return left(new BadRequestError(`Dispute cannot be withdrawn while it is ${dispute.status}`));
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.dispute.update({
        where: { id: input.disputeId },
        data: { status: 'CANCELLED', resolvedAt: new Date() },
      });

      await tx.order.update({
        where: { id: dispute.orderId },
        data: { status: 'DELIVERED', escrowStatus: 'HELD' },
      });
    });

    const otherUserId = dispute.order.buyerId === input.userId ? dispute.order.sellerId : dispute.order.buyerId;
    await this.notificationService.notifyDispute(otherUserId, dispute.id, 'A disputa foi retirada pelo solicitante');

    return right(undefined);
  }
}
