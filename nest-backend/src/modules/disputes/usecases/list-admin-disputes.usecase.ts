import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';
import { GetDisputeOutput } from '../dtos/dispute.dto';
import { DisputeStatus } from '../domain/dispute-state';

@Injectable()
export class ListAdminDisputesUseCase {
  constructor(private readonly disputes: DisputeDatabaseRepository) {}

  async execute(input: {
    status?: DisputeStatus;
    limit?: number;
  }): Promise<Either<AppError, { disputes: GetDisputeOutput[] }>> {
    const result = await this.disputes.findAdminQueue(input.status, input.limit ?? 100);
    if (result.isLeft()) return left(result.value);
    return right({ disputes: result.value });
  }
}
