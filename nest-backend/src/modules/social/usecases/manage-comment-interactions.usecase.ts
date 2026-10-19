import { Injectable } from '@nestjs/common';
import { ReportReason } from '@prisma/client';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { CommentInteractionDatabaseRepository } from '../data/repositories/comment-interaction-database.repository';

@Injectable()
export class ManageCommentInteractionsUseCase {
  constructor(private readonly repository: CommentInteractionDatabaseRepository) {}

  repost(userId: string, commentId: string) {
    return this.repository.setReposted(userId, commentId, true);
  }

  unrepost(userId: string, commentId: string) {
    return this.repository.setReposted(userId, commentId, false);
  }

  bookmark(userId: string, commentId: string, active: boolean) {
    return this.repository.setBookmarked(userId, commentId, active);
  }

  async bookmarks(userId: string, limit: number, cursor?: string) {
    const decoded = await this.repository.parseBookmarkCursor(cursor, userId);
    if (decoded.isLeft()) return left(decoded.value);
    const result = await this.repository.findBookmarks(userId, limit, decoded.value);
    return result.isLeft() ? left(result.value) : right(result.value);
  }

  async report(userId: string, commentId: string, reason: ReportReason, description?: string): Promise<Either<AppError, unknown>> {
    if (!Object.values(ReportReason).includes(reason)) return left(new BadRequestError('Invalid report reason'));
    return this.repository.report(userId, commentId, reason, description);
  }
}
