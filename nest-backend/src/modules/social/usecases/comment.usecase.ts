import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { PrismaCommentRepository } from '../data/repositories/comment-database.repository';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { CreateCommentInput, CreateCommentOutput } from '../dtos/social.dto';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { StoryAudience } from '@prisma/client';

@Injectable()
export class CommentUseCase {
  constructor(
    private readonly commentRepository: PrismaCommentRepository,
    private readonly notificationService: NotificationService,
    private readonly postRepository: PrismaPostRepository,
  ) {}

  async execute(input: CreateCommentInput): Promise<Either<AppError, CreateCommentOutput>> {
    const post = await this.postRepository.findById(input.postId, input.userId);
    if (post.isLeft()) return left(post.value);
    if (!post.value) return left(new NotFoundError('Post'));
    if (post.value.audience === StoryAudience.CLOSE_FRIENDS && input.mentionIds?.length) {
      return left(new BadRequestError('Não é possível mencionar pessoas em comentários privados'));
    }
    if (input.parentId) {
      const parent = await this.commentRepository.belongsToPost(input.parentId, input.postId, input.userId);
      if (parent.isLeft()) return left(parent.value);
      if (!parent.value) return left(new BadRequestError('Comentário pai inválido para este post'));
    }
    const result = await this.commentRepository.createWithCount({
      content: input.content,
      post: { connect: { id: input.postId } },
      user: { connect: { id: input.userId } },
      ...(input.parentId ? { parent: { connect: { id: input.parentId } } } : {}),
    }, input.postId, post.value.userId, input.userId);
    if (result.isLeft()) return left(result.value);

    if (!result.value.isHidden && input.mentionIds && input.mentionIds.length > 0) {
      const uniqueIds = [...new Set(input.mentionIds)].filter((id) => id !== input.userId);
      if (uniqueIds.length > 0) {
        await this.commentRepository.createMentions(result.value.id, uniqueIds);

        const authorHandle = result.value.user?.username ?? result.value.user?.displayName ?? 'alguem';
        for (const mentionedId of uniqueIds) {
          this.notificationService
            .notifyMention(mentionedId, `@${authorHandle} te mencionou em um comentário`, result.value.id)
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
