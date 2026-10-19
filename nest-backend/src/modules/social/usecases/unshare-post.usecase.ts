import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostDatabaseRepository } from '../data/repositories/post-database.repository';
import { ShareDatabaseRepository } from '../data/repositories/share-database.repository';

@Injectable()
export class UnsharePostUseCase {
  constructor(
    private readonly postRepository: PostDatabaseRepository,
    private readonly shareRepository: ShareDatabaseRepository,
  ) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, { active: boolean; count: number }>> {
    const result = await this.shareRepository.setPostShare(input.userId, input.postId, false);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
