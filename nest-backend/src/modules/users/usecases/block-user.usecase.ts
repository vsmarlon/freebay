import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { BlockRepository } from '../repositories/block.repository';
import { BlockResponse } from '../mappers/user.mapper';
import { BlockUserInput } from '../dtos/user.dto';

@Injectable()
export class BlockUserUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly blockRepository: BlockRepository,
  ) {}

  async execute(input: BlockUserInput): Promise<Either<AppError, BlockResponse>> {
    if (input.blockerId === input.blockedId) {
      return left(new BadRequestError('Cannot block yourself'));
    }

    const targetResult = await this.userRepository.findById(input.blockedId);
    if (isLeft(targetResult)) {
      return left(targetResult.value);
    }
    if (!targetResult.value) {
      return left(new NotFoundError('User'));
    }

    try {
      await this.blockRepository.block(input.blockerId, input.blockedId);
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2002') {
        return left(new BadRequestError('Already blocked'));
      }
      return left(new AppError('DB_ERROR', 'Erro ao bloquear usuário'));
    }

    return right({ blocked: true });
  }
}
