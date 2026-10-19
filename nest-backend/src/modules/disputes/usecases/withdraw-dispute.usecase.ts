import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, BadRequestError } from '@/shared/core/errors';
import { NotificationService } from '../../notifications/services/notification.service';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';

@Injectable()
export class WithdrawDisputeUseCase {
  constructor(
    private disputeRepo: DisputeDatabaseRepository,
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

    await this.disputeRepo.executeWithdrawal(input.disputeId, dispute.orderId);

    const otherUserId = dispute.order.buyerId === input.userId ? dispute.order.sellerId : dispute.order.buyerId;
    await this.notificationService.notifyDispute(otherUserId, dispute.id, dispute.orderId, 'A disputa foi retirada pelo solicitante');

    return right(undefined);
  }
}
