import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PrismaCommentRepository } from '../data/repositories/comment-database.repository';
import { CreateCommentInput, CreateCommentOutput } from '../dtos/social.dto';
import { NotificationService } from '@/modules/notifications/services/notification.service';

@Injectable()
export class CommentUseCase {
  constructor(
    private readonly commentRepository: PrismaCommentRepository,
    private readonly postRepository: PrismaPostRepository,
    private readonly notificationService: NotificationService,
  ) {}

  async execute(input: CreateCommentInput): Promise<Either<AppError, CreateCommentOutput>> {
    const result = await this.commentRepository.create({
      content: input.content,
      post: { connect: { id: input.postId } },
      user: { connect: { id: input.userId } },
      ...(input.parentId ? { parent: { connect: { id: input.parentId } } } : {}),
    });
    if (isLeft(result)) return left(result.value);

    await this.postRepository.update(input.postId, { commentsCount: { increment: 1 } });

    if (input.mentionIds && input.mentionIds.length > 0) {
      const uniqueIds = [...new Set(input.mentionIds)].filter((id) => id !== input.userId);
      if (uniqueIds.length > 0) {
        await this.commentRepository.createMentions(result.value.id, uniqueIds);

        const authorName = result.value.user?.displayName ?? 'Alguém';
        for (const mentionedId of uniqueIds) {
          this.notificationService
            .notifyMention(mentionedId, `@${authorName} te mencionou em um comentário`, result.value.id)
            .catch(() => {});
        }
      }
    }

    return right({
      id: result.value.id,
      postId: input.postId,
      userId: input.userId,
      content: input.content,
      createdAt: result.value.createdAt,
    });
  }
}
