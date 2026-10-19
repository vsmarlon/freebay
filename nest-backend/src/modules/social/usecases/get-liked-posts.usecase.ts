import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { LikeDatabaseRepository } from '../data/repositories/like-database.repository';
import { PostResponse } from '../types/social.types';

@Injectable()
export class GetLikedPostsUseCase {
  constructor(private readonly likeRepository: LikeDatabaseRepository) {}

  async execute(userId: string): Promise<Either<AppError, PostResponse[]>> {
    const result = await this.likeRepository.findLikedByUserId(userId);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
