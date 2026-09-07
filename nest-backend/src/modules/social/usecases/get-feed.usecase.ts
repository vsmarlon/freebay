import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { FeedQuery, FeedResult } from '../types/social.types';

@Injectable()
export class GetFeedUseCase {
  constructor(private readonly postRepository: PrismaPostRepository) {}

  async execute(input: FeedQuery): Promise<Either<AppError, FeedResult>> {
    const result = await this.postRepository.findFeed(input);
    if (isLeft(result)) return left(result.value);
    return right(result.value);
  }
}
