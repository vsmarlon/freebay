import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError } from '@/shared/core/errors';
import { GetDisputeOutput } from '../dtos/dispute.dto';
import { DisputeRepository } from '../domain/repositories/dispute.repository';

@Injectable()
export class GetDisputeUseCase {
  constructor(private disputeRepo: DisputeRepository) {}

  async execute(disputeId: string, userId: string): Promise<Either<AppError, GetDisputeOutput>> {
    const result = await this.disputeRepo.findByIdWithDetails(disputeId);
    if (result.isLeft()) return left(result.value);

    const dispute = result.value;
    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    const isParticipant = dispute.order.buyerId === userId || dispute.order.sellerId === userId;
    if (!isParticipant) {
      return left(new UnauthorizedError('Not authorized to view this dispute'));
    }

    return right(dispute);
  }
}
