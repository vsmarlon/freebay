import { Injectable } from '@nestjs/common';
import { Either } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { LikeDatabaseRepository } from '../data/repositories/like-database.repository';
import { LikePostInput } from '../dtos/social.dto';
import { MutationState } from '../types/social.types';

@Injectable()
export class UnlikePostUseCase {
  constructor(private readonly likeRepository: LikeDatabaseRepository) {}

  async execute(input: LikePostInput): Promise<Either<AppError, MutationState>> {
    return this.likeRepository.setPostLike(input.userId, input.postId, false);
  }
}
