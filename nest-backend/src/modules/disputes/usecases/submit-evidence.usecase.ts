import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, BadRequestError, ConflictError } from '@/shared/core/errors';
import { Prisma } from '@prisma/client';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';
import { partyOf } from '../domain/dispute-state';

@Injectable()
export class SubmitEvidenceUseCase {
  constructor(
    private disputeRepo: DisputeDatabaseRepository,
    private transitionPolicy: DisputeTransitionPolicy,
  ) {}

  async execute(input: { disputeId: string; userId: string; evidence: Prisma.InputJsonValue }): Promise<Either<AppError, void>> {
    const disputeResult = await this.disputeRepo.findById(input.disputeId);
    if (disputeResult.isLeft()) return left(disputeResult.value);

    const dispute = disputeResult.value;
    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    const party = partyOf(dispute.order, input.userId);
    if (!party) {
      return left(new UnauthorizedError('Not authorized'));
    }

    if (!this.transitionPolicy.canSubmitEvidence(dispute.status, party)) {
      return left(new BadRequestError(`Evidence cannot be submitted while dispute is ${dispute.status}`));
    }

    const updateResult = await this.disputeRepo.submitEvidence({
      disputeId: input.disputeId,
      expectedStatus: dispute.status,
      party,
      evidence: input.evidence,
    });
    if (updateResult.isLeft()) return left(updateResult.value);
    if (!updateResult.value) {
      return left(new ConflictError('Dispute changed before evidence could be recorded'));
    }

    return right(undefined);
  }
}
