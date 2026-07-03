import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { BlockRepository } from '../repositories/block.repository';
import { BlockResponse } from '../mappers/user.mapper';
import { BlockUserInput } from '../dtos/user.dto';

@Injectable()
export class UnblockUserUseCase {
  constructor(private readonly blockRepository: BlockRepository) {}

  async execute(input: BlockUserInput): Promise<Either<AppError, BlockResponse>> {
    try {
      await this.blockRepository.unblock(input.blockerId, input.blockedId);
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2025') {
        return left(new BadRequestError('Not blocked'));
      }
      return left(new AppError('DB_ERROR', 'Erro ao desbloquear usuário'));
    }

    return right({ blocked: false });
  }
}
