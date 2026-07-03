import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository, FeedQuery } from '../domain/repositories/post.repository';
import { PostPayload } from '../types/social.types';

@Injectable()
export class GetFeedUseCase {
  constructor(private readonly postRepository: PostRepository) {}

  async execute(input: FeedQuery): Promise<Either<AppError, PostPayload[]>> {
    const result = await this.postRepository.findFeed(input);
    if (isLeft(result)) return left(result.value);
    return right(result.value);
  }
}
