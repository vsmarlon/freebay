import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { GetUserDisputesOutput } from '../dtos/dispute.dto';
import { PrismaDisputeRepository } from '../repositories/dispute.repository';

@Injectable()
export class GetUserDisputesUseCase {
  constructor(private disputeRepo: PrismaDisputeRepository) {}

  async execute(userId: string): Promise<Either<AppError, GetUserDisputesOutput>> {
    const disputes = await this.disputeRepo.findByUserId(userId);

    return right(disputes);
  }
}
