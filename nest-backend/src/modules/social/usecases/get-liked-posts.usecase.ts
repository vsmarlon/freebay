import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaLikeRepository } from '../data/repositories/like-database.repository';

@Injectable()
export class GetLikedPostsUseCase {
  constructor(private readonly likeRepository: PrismaLikeRepository) {}

  async execute(userId: string): Promise<Either<AppError, unknown[]>> {
    const result = await this.likeRepository.findLikedByUserId(userId);
    if (isLeft(result)) return left(result.value);
    return right(result.value);
  }
}
