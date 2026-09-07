import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaBlockRepository } from '../data/repositories/block-database.repository';
import { BlockResponse } from '../mappers/user.mapper';
import { BlockUserInput } from '../dtos/user.dto';

@Injectable()
export class UnblockUserUseCase {
  constructor(private readonly blockRepository: PrismaBlockRepository) {}

  async execute(input: BlockUserInput): Promise<Either<AppError, BlockResponse>> {
    const unblockResult = await this.blockRepository.unblock(input.blockerId, input.blockedId);
    if (unblockResult.isLeft()) return left(unblockResult.value);
    return right({ blocked: false });
  }
}
