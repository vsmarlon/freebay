import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { LikeRepository } from '../domain/repositories/like.repository';

@Injectable()
export class GetLikedPostsUseCase {
  constructor(private readonly likeRepository: LikeRepository) {}

  async execute(userId: string): Promise<Either<AppError, unknown[]>> {
    const result = await this.likeRepository.findLikedByUserId(userId);
    if (isLeft(result)) return left(result.value);
    return right(result.value);
  }
}
