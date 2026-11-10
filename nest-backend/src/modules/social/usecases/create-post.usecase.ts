import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { PostType, StoryAudience } from '@prisma/client';
import { PostDatabaseRepository } from '../data/repositories/post-database.repository';
import { CreatePostInput, CreatePostOutput } from '../dtos/social.dto';
import { NotificationService } from '@/modules/notifications/services/notification.service';

@Injectable()
export class CreatePostUseCase {
  constructor(
    private readonly postRepository: PostDatabaseRepository,
    private readonly notificationService: NotificationService,
  ) {}

  async execute(input: CreatePostInput): Promise<Either<AppError, CreatePostOutput>> {
    if (input.audience === StoryAudience.CLOSE_FRIENDS &&
        (input.type !== PostType.REGULAR ||
         (input.media?.some((item) => !item.url.startsWith('/media/privatepost/')) ?? false) ||
         (input.mentionIds?.length ?? 0) > 0)) {
      return left(new BadRequestError('Posts para amigos próximos aceitam apenas texto e mídia enviada pelo app, sem menções ou produto'));
    }
    const result = await this.postRepository.create({
      content: input.content ?? null,
      type: input.type,
      audience: input.audience ?? StoryAudience.EVERYONE,
      user: { connect: { id: input.userId } },
      media: input.media?.length ? {
        create: input.media.map((item, order) => ({
          url: item.url,
          thumbnailUrl: item.thumbnailUrl,
          type: item.type,
          blurHash: input.audience === StoryAudience.CLOSE_FRIENDS ? null : item.blurHash,
          altText: item.altText,
          hotspots: item.hotspots,
          durationMs: item.durationMs,
          coverTimestampMs: item.coverTimestampMs,
          order,
        })),
      } : undefined,
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
      isQuote: false,
      content: post.content,
      media: post.media.map(({ blurHash, ...item }) => ({
        ...item,
        ...(post.audience !== StoryAudience.CLOSE_FRIENDS && blurHash ? { blurHash } : {}),
      })),
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
