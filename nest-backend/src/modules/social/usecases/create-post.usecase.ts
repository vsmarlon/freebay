import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { PostType, StoryAudience } from '@prisma/client';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { CreatePostInput, CreatePostOutput } from '../dtos/social.dto';
import { NotificationService } from '@/modules/notifications/services/notification.service';

@Injectable()
export class CreatePostUseCase {
  constructor(
    private readonly postRepository: PrismaPostRepository,
    private readonly notificationService: NotificationService,
  ) {}

  async execute(input: CreatePostInput): Promise<Either<AppError, CreatePostOutput>> {
    if (input.audience === StoryAudience.CLOSE_FRIENDS &&
        (input.type !== PostType.REGULAR ||
         (input.imageUrl != null && !input.imageUrl.startsWith('/media/privatepost/')) ||
         (input.mentionIds?.length ?? 0) > 0)) {
      return left(new BadRequestError('Posts para amigos próximos aceitam apenas texto e imagem enviada pelo app, sem menções ou produto'));
    }
    const result = await this.postRepository.create({
      content: input.content ?? null,
      imageUrl: input.imageUrl ?? null,
      type: input.type,
      audience: input.audience ?? StoryAudience.EVERYONE,
      user: { connect: { id: input.userId } },
    });
    if (result.isLeft()) return left(result.value);

    const post = result.value;

    if (input.mentionIds && input.mentionIds.length > 0) {
      const uniqueIds = [...new Set(input.mentionIds)].filter((id) => id !== input.userId);
      if (uniqueIds.length > 0) {
        await this.postRepository.createMentions(post.id, uniqueIds);

        const authorHandle = post.user?.username ?? post.user?.displayName ?? 'alguem';
        for (const mentionedId of uniqueIds) {
          this.notificationService
            .notifyMention(mentionedId, `@${authorHandle} te mencionou em uma publicação`, post.id)
            .catch(() => {});
        }
      }
    }

    return right({
      id: post.id,
      content: post.content,
      imageUrl: post.imageUrl,
      type: post.type,
      audience: post.audience,
      userId: post.userId,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      sharesCount: post.sharesCount,
      createdAt: post.createdAt,
      user: post.user,
    });
  }
}
