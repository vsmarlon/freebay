import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { CommentDatabaseRepository } from '../data/repositories/comment-database.repository';
import { CommentReplyPermission } from '@prisma/client';

@Injectable()
export class ManageCommentVisibilityUseCase {
  constructor(private readonly comments: CommentDatabaseRepository) {}

  async execute(commentId: string, postAuthorId: string, hidden: boolean): Promise<Either<AppError, void>> {
    const result = await this.comments.setAuthorHidden(commentId, postAuthorId, hidden);
    if (result.isLeft()) return left(result.value);
    return result.value ? right(undefined) : left(new NotFoundError('Comentário'));
  }

  async setPermission(postId: string, postAuthorId: string, permission: CommentReplyPermission): Promise<Either<AppError, void>> {
    const result = await this.comments.setReplyPermission(postId, postAuthorId, permission);
    if (result.isLeft()) return left(result.value);
    return result.value ? right(undefined) : left(new NotFoundError('Post'));
  }

  async setConversationPreference(postId: string, userId: string, enabled: boolean, mute: boolean): Promise<Either<AppError, void>> {
    const result = await this.comments.setConversationPreference(postId, userId, enabled, mute);
    if (result.isLeft()) return left(result.value);
    return result.value ? right(undefined) : left(new NotFoundError('Post'));
  }
}
