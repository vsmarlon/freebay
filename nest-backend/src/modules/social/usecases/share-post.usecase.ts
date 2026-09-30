import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { StoryAudience } from '@prisma/client';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PrismaShareRepository } from '../data/repositories/share-database.repository';

@Injectable()
export class SharePostUseCase {
  constructor(
    private readonly postRepository: PrismaPostRepository,
    private readonly shareRepository: PrismaShareRepository,
  ) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, { active: boolean; count: number }>> {
    const postResult = await this.postRepository.findById(input.postId, input.userId);
    if (postResult.isLeft()) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));
    if (postResult.value.audience === StoryAudience.CLOSE_FRIENDS) {
      return left(new BadRequestError('Posts para amigos próximos não podem ser repostados'));
    }

    const result = await this.shareRepository.setPostShare(input.userId, input.postId, true);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
