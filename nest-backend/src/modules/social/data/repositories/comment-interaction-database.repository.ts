import { Injectable } from '@nestjs/common';
import { Prisma, ReportReason, ReportTargetType } from '@prisma/client';
import { left, RepositoryResponse, right } from '@/shared/core/either';
import { BadRequestError, ConflictError, DatabaseError, NotFoundError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { commentFlatIncludeForViewer, commentVisibilityWhere } from '../../types/social.types';
import { postVisibilityWhere } from './post-query-helpers';

@Injectable()
export class CommentInteractionDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {}

  async setReposted(userId: string, commentId: string, active: boolean): RepositoryResponse<{ active: boolean; id?: string }> {
    if (!active) return repositoryResponse(async () => {
      await this.prisma.commentShare.deleteMany({ where: { userId, commentId } });
      return { active: false };
    }, 'Unable to remove comment repost');

    return repositoryResponse(async () => this.prisma.$transaction(async (tx) => {
      const comment = await this.visibleComment(tx, commentId, userId);
      if (!comment) return null;
      const share = await tx.commentShare.upsert({
        where: { userId_commentId: { userId, commentId } },
        create: { userId, commentId, postId: comment.postId },
        update: {},
        select: { id: true },
      });
      return { active: true, id: share.id };
    }), 'Unable to repost comment').then((result) => result.isLeft() ? left(result.value) : result.value
      ? right(result.value)
      : left(new NotFoundError('Comment')));
  }

  async setBookmarked(userId: string, commentId: string, active: boolean): RepositoryResponse<{ active: boolean }> {
    if (!active) return repositoryResponse(async () => {
      await this.prisma.commentBookmark.deleteMany({ where: { userId, commentId } });
      return { active: false };
    }, 'Unable to remove comment bookmark');

    return repositoryResponse(async () => this.prisma.$transaction(async (tx) => {
      if (!await this.visibleComment(tx, commentId, userId)) return null;
      await tx.commentBookmark.upsert({
        where: { userId_commentId: { userId, commentId } },
        create: { userId, commentId },
        update: {},
      });
      return { active: true };
    }), 'Unable to bookmark comment').then((result) => result.isLeft() ? left(result.value) : result.value
      ? right(result.value)
      : left(new NotFoundError('Comment')));
  }

  async findBookmarks(userId: string, limit: number, cursor?: { createdAt: Date; id: string }) {
    return repositoryResponse(async () => {
      const rows = await this.prisma.commentBookmark.findMany({
        where: {
          userId,
          comment: this.publicCommentWhere(userId),
          ...(cursor ? { OR: [
            { createdAt: { lt: cursor.createdAt } },
            { createdAt: cursor.createdAt, id: { lt: cursor.id } },
          ] } : {}),
        },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: limit + 1,
        include: { comment: { include: commentFlatIncludeForViewer(userId) } },
      });
      const hasMore = rows.length > limit;
      const page = rows.slice(0, limit);
      const last = page.at(-1);
      return {
        items: page.map(({ comment }) => {
          const { commentLikes, clientRequestId: _requestId, clientRequestHash: _requestHash,
            isHidden: _moderationHidden, authorHiddenAt: _authorHiddenAt, ...fields } = comment;
          return { ...fields, isLiked: commentLikes.length > 0 };
        }),
        nextCursor: hasMore && last ? Buffer.from(JSON.stringify({
          userId, createdAt: last.createdAt.toISOString(), id: last.id,
        })).toString('base64url') : null,
      };
    }, 'Unable to list comment bookmarks');
  }

  async report(userId: string, commentId: string, reason: ReportReason, description?: string) {
    try {
      const result = await this.prisma.$transaction(async (tx) => {
        if (!await this.visibleComment(tx, commentId, userId)) return { missing: true as const };
        const existing = await tx.report.findUnique({
          where: { reporterId_reportedCommentId: { reporterId: userId, reportedCommentId: commentId } },
          select: { id: true },
        });
        if (existing) return { duplicate: true as const };
        return tx.report.create({ data: {
          reporterId: userId,
          reportedCommentId: commentId,
          targetType: ReportTargetType.COMMENT,
          reason,
          description,
        }, select: { id: true, reporterId: true, reportedCommentId: true, targetType: true, reason: true, description: true, status: true, createdAt: true } });
      });
      if ('missing' in result) return left(new NotFoundError('Comment'));
      if ('duplicate' in result) return left(new ConflictError('You have already reported this comment'));
      return right(result);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        return left(new ConflictError('You have already reported this comment'));
      }
      return left(new DatabaseError('Unable to report comment'));
    }
  }

  async parseBookmarkCursor(value: string | undefined, userId: string): Promise<RepositoryResponse<{ createdAt: Date; id: string } | undefined>> {
    if (!value) return right(undefined);
    try {
      const decoded: unknown = JSON.parse(Buffer.from(value, 'base64url').toString('utf8'));
      if (typeof decoded !== 'object' || decoded === null || Array.isArray(decoded)) throw new Error();
      const cursor = decoded as Record<string, unknown>;
      if (cursor.userId !== userId || typeof cursor.id !== 'string' || typeof cursor.createdAt !== 'string' || Number.isNaN(Date.parse(cursor.createdAt))) throw new Error();
      return right({ id: cursor.id, createdAt: new Date(cursor.createdAt) });
    } catch {
      return left(new BadRequestError('Invalid bookmark cursor'));
    }
  }

  private publicCommentWhere(viewerId: string): Prisma.CommentWhereInput {
    return {
      deletedAt: null,
      isHidden: false,
      authorHiddenAt: null,
      AND: [
        commentVisibilityWhere(viewerId),
        { user: { blocksGiven: { none: { blockedId: viewerId } }, blocksReceived: { none: { blockerId: viewerId } } } },
        { post: { deletedAt: null, AND: [postVisibilityWhere(viewerId)] } },
      ],
    };
  }

  private visibleComment(tx: Prisma.TransactionClient, commentId: string, viewerId: string) {
    return tx.comment.findFirst({
      where: { id: commentId, ...this.publicCommentWhere(viewerId) },
      select: { id: true, postId: true },
    });
  }
}
