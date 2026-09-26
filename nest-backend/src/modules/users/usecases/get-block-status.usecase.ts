import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { BlockRepository } from '../domain/repositories/block.repository';

@Injectable()
export class GetBlockStatusUseCase {
  constructor(private readonly blockRepository: BlockRepository) {}

  async execute(input: { blockerId: string; blockedId: string }): Promise<Either<AppError, { isBlocked: boolean }>> {
    const result = await this.blockRepository.isBlocked(input.blockerId, input.blockedId);
    if (result.isLeft()) return left(result.value);
    return right({ isBlocked: result.value });
  }
}
