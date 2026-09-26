import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, BadRequestError } from '@/shared/core/errors';
import { DisputeStatus, Prisma } from '@prisma/client';
import { PrismaDisputeRepository } from '../data/repositories/dispute-database.repository';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';

@Injectable()
export class SubmitEvidenceUseCase {
  constructor(
    private disputeRepo: PrismaDisputeRepository,
    private transitionPolicy: DisputeTransitionPolicy,
  ) {}

  async execute(input: { disputeId: string; userId: string; evidence: Prisma.InputJsonValue }): Promise<Either<AppError, void>> {
    const disputeResult = await this.disputeRepo.findById(input.disputeId);
    if (disputeResult.isLeft()) return left(disputeResult.value);

    const dispute = disputeResult.value;
    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    const isBuyer = dispute.order.buyerId === input.userId;
    const isSeller = dispute.order.sellerId === input.userId;
    if (!isBuyer && !isSeller) {
      return left(new UnauthorizedError('Not authorized'));
    }

    if (!this.transitionPolicy.canSubmitEvidence(dispute.status)) {
      return left(new BadRequestError(`Evidence cannot be submitted while dispute is ${dispute.status}`));
    }

    const updateData = isBuyer
      ? { buyerEvidence: input.evidence, status: DisputeStatus.AWAITING_SELLER }
      : { sellerEvidence: input.evidence, status: DisputeStatus.AWAITING_BUYER };

    const updateResult = await this.disputeRepo.update(input.disputeId, updateData);
    if (updateResult.isLeft()) return left(updateResult.value);

    return right(undefined);
  }
}
