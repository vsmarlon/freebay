import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';
import { FeedQuery, FeedResult } from '../types/social.types';

@Injectable()
export class GetFeedUseCase {
  constructor(private readonly postRepository: PostRepository) {}

  async execute(input: FeedQuery): Promise<Either<AppError, FeedResult>> {
    const result = await this.postRepository.findFeed(input);
    if (isLeft(result)) return left(result.value);
    return right(result.value);
  }
}
