import { Injectable } from '@nestjs/common';
import { Either, left } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { StoryAudience } from '@prisma/client';
import { PostDatabaseRepository } from '../data/repositories/post-database.repository';
import { ShareDatabaseRepository } from '../data/repositories/share-database.repository';
import { MutationState } from '../types/social.types';

@Injectable()
export class SharePostUseCase {
  constructor(
    private readonly postRepository: PostDatabaseRepository,
    private readonly shareRepository: ShareDatabaseRepository,
  ) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, MutationState>> {
    const postResult = await this.postRepository.findById(input.postId, input.userId);
    if (postResult.isLeft()) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));
    if (postResult.value.audience === StoryAudience.CLOSE_FRIENDS) {
      return left(new BadRequestError('Posts para amigos próximos não podem ser repostados'));
    }

    return this.shareRepository.setPostShare(input.userId, input.postId, true);
  }
}
