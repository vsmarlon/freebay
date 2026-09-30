import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { BlockRepository } from '../domain/repositories/block.repository';
import { BlockResponse } from '../dtos/user-response.class';
import { BlockUserInput } from '../dtos/user.dto';

@Injectable()
export class UnblockUserUseCase {
  constructor(private readonly blockRepository: BlockRepository) {}

  async execute(input: BlockUserInput): Promise<Either<AppError, BlockResponse>> {
    const unblockResult = await this.blockRepository.unblock(input.blockerId, input.blockedId);
    if (unblockResult.isLeft()) return left(unblockResult.value);
    return right({ blocked: false });
  }
}
