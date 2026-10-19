import { Injectable } from '@nestjs/common';
import { createHash, randomUUID } from 'node:crypto';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { CommentDatabaseRepository } from '../data/repositories/comment-database.repository';
import { PostDatabaseRepository } from '../data/repositories/post-database.repository';
import { CreateCommentInput, CreateCommentOutput } from '../dtos/social.dto';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { StoryAudience } from '@prisma/client';

@Injectable()
export class CommentUseCase {
  constructor(
    private readonly commentRepository: CommentDatabaseRepository,
    private readonly notificationService: NotificationService,
    private readonly postRepository: PostDatabaseRepository,
  ) {}

  async execute(input: CreateCommentInput): Promise<Either<AppError, CreateCommentOutput>> {
    const post = await this.postRepository.findById(input.postId, input.userId);
    if (post.isLeft()) return left(post.value);
    if (!post.value) return left(new NotFoundError('Post'));
    if (post.value.audience === StoryAudience.CLOSE_FRIENDS && input.mentionIds?.length) {
      return left(new BadRequestError('Não é possível mencionar pessoas em comentários privados'));
    }
    const uniqueMentions = [...new Set(input.mentionIds ?? [])].filter((id) => id !== input.userId).sort();
    const requestId = input.clientRequestId ?? randomUUID();
    const media = input.media?.map((file) => ({
      buffer: file.buffer,
      mimetype: file.mimetype,
      size: file.size,
      sha256: createHash('sha256').update(file.buffer).digest('hex'),
    }));
    const digestPayload = {
      postId: input.postId, content: input.content, parentId: input.parentId ?? null, mentionIds: uniqueMentions,
      ...(media?.length ? { media: media.map(({ mimetype, size, sha256 }) => ({ mimetype, size, sha256 })) } : {}),
    };
    const digest = createHash('sha256').update(JSON.stringify(digestPayload)).digest('hex');
    const result = await this.commentRepository.createIdempotent({
      content: input.content,
      post: { connect: { id: input.postId } },
      user: { connect: { id: input.userId } },
      ...(input.parentId ? { parent: { connect: { id: input.parentId } } } : {}),
    }, { postId: input.postId, userId: input.userId, requestId, digest, mentionIds: uniqueMentions, media });
    if (result.isLeft()) return left(result.value);
    for (const notification of result.value.notifications) this.notificationService.deliverPersisted(notification.userId, notification.id, notification.type, notification.data);

    return right({
      id: result.value.comment.id,
      postId: input.postId,
      userId: input.userId,
      content: result.value.comment.content,
      createdAt: result.value.comment.createdAt,
      ...(result.value.comment.media?.length ? { media: result.value.comment.media } : {}),
    });
  }
}
