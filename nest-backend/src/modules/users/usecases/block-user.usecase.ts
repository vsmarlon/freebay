import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { BlockRepository } from '../domain/repositories/block.repository';
import { BlockResponse } from '../mappers/user.mapper';
import { BlockUserInput } from '../dtos/user.dto';

@Injectable()
export class BlockUserUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly blockRepository: BlockRepository,
  ) {}

  async execute(input: BlockUserInput): Promise<Either<AppError, BlockResponse>> {
    if (input.blockerId === input.blockedId) {
      return left(new BadRequestError('Cannot block yourself'));
    }

    const targetResult = await this.userRepository.findById(input.blockedId);
    if (targetResult.isLeft()) {
      return left(targetResult.value);
    }
    if (!targetResult.value) {
      return left(new NotFoundError('User'));
    }

    const blockResult = await this.blockRepository.block(input.blockerId, input.blockedId);
    if (blockResult.isLeft()) return left(blockResult.value);

    return right({ blocked: true });
  }
}
