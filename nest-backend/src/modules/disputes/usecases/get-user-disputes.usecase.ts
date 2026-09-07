import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { GetUserDisputesOutput } from '../dtos/dispute.dto';
import { PrismaDisputeRepository } from '../data/repositories/dispute-database.repository';

@Injectable()
export class GetUserDisputesUseCase {
  constructor(private disputeRepo: PrismaDisputeRepository) {}

  async execute(userId: string): Promise<Either<AppError, GetUserDisputesOutput>> {
    const result = await this.disputeRepo.findByUserId(userId);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
