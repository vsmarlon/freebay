import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { CommentDatabaseRepository } from '../data/repositories/comment-database.repository';
import { CommentCursor, CommentSort, decodeCommentCursor, CommentCursorScope } from '../types/comment-cursor';

@Injectable()
export class GetConversationUseCase {
  constructor(private readonly comments: CommentDatabaseRepository) {}

  async roots(input: { postId: string; viewerId?: string; limit: number; sort: CommentSort; cursor?: string }): Promise<Either<AppError, unknown>> {
    const viewerId = input.viewerId ?? '';
    const cursor = this.decode(input.cursor, CommentCursorScope.CONVERSATION, input.postId, viewerId, input.sort);
    if (cursor instanceof BadRequestError) return left(cursor);
    const result = await this.comments.findConversationPage(input.postId, viewerId, input.limit, input.sort, cursor);
    return result.isLeft() ? left(result.value) : right(result.value);
  }

  async context(input: { commentId: string; viewerId?: string; limit: number; sort: CommentSort; replyCursor?: string; ancestorCursor?: string }): Promise<Either<AppError, unknown>> {
    const viewerId = input.viewerId ?? '';
    const replyCursor = this.decode(input.replyCursor, CommentCursorScope.CONTEXT_REPLIES, input.commentId, viewerId, input.sort);
    if (replyCursor instanceof BadRequestError) return left(replyCursor);
    const ancestorCursor = this.decode(input.ancestorCursor, CommentCursorScope.CONTEXT_ANCESTORS, input.commentId, viewerId, CommentSort.RECENT);
    if (ancestorCursor instanceof BadRequestError) return left(ancestorCursor);
    const result = await this.comments.findCommentContext(input.commentId, viewerId, input.limit, input.sort, replyCursor, ancestorCursor);
    return result.isLeft() ? left(result.value) : right(result.value);
  }

  async hiddenReplies(input: { postId: string; viewerId?: string; limit: number; cursor?: string }): Promise<Either<AppError, unknown>> {
    const viewerId = input.viewerId ?? '';
    let cursor: { createdAt: Date; id: string } | undefined;
    if (input.cursor) {
      try {
        const parsed: unknown = JSON.parse(Buffer.from(input.cursor, 'base64url').toString('utf8'));
        if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) throw new Error();
        const data = parsed as Record<string, unknown>;
        if (data.postId !== input.postId || data.viewerId !== viewerId || typeof data.id !== 'string' || typeof data.createdAt !== 'string' || Number.isNaN(Date.parse(data.createdAt))) throw new Error();
        cursor = { id: data.id, createdAt: new Date(data.createdAt) };
      } catch {
        return left(new BadRequestError('Invalid hidden-replies cursor'));
      }
    }
    const result = await this.comments.findAuthorHidden(input.postId, viewerId, input.limit, cursor);
    return result.isLeft() ? left(result.value) : right(result.value);
  }

  async setHidden(commentId: string, authorId: string, hidden: boolean): Promise<Either<AppError, void>> {
    const result = await this.comments.setAuthorHidden(commentId, authorId, hidden);
    if (result.isLeft()) return left(result.value);
    return result.value ? right(undefined) : left(new NotFoundError('Comentário'));
  }

  private decode(value: string | undefined, scope: CommentCursorScope, ownerId: string, viewerId: string, sort: CommentSort): CommentCursor | undefined | BadRequestError {
    if (!value) return undefined;
    const cursor = decodeCommentCursor(value);
    if (!cursor || cursor.scope !== scope || cursor.ownerId !== ownerId || cursor.viewerId !== viewerId || cursor.sort !== sort) {
      return new BadRequestError('Invalid comment cursor');
    }
    return cursor;
  }
}
