import { Injectable } from '@nestjs/common';
import { NotificationType, Prisma, PostType, StoryAudience } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { deleteUpload, saveUpload } from '@/shared/utils/file.utils';
import { left, right, RepositoryResponse } from '@/shared/core/either';
import { BadRequestError, ConflictError, DatabaseError, ForbiddenError } from '@/shared/core/errors';
import { POST_INCLUDE, PostResponse } from '../../types/social.types';
import { normalizePostsForViewer } from './post-query-helpers';

@Injectable()
export class QuoteDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(options: {
    userId: string; content: string; sourcePostId?: string; sourceCommentId?: string;
    mentionIds: string[]; requestId: string; digest: string;
    imageBlurHash?: string;
    image?: { buffer: Buffer; mimeType: string; size: number; sha256: string };
  }): RepositoryResponse<{ post: PostResponse; mentionIds: string[]; notifications: Prisma.NotificationGetPayload<Record<string, never>>[] }> {
    let imageUrl: string | undefined;
    let transactionCommitted = false;
    try {
      const value = await this.prisma.$transaction(async (tx) => {
        const existing = await tx.post.findUnique({ where: { userId_clientRequestId: { userId: options.userId, clientRequestId: options.requestId } }, include: POST_INCLUDE });
        if (existing) return existing.clientRequestHash === options.digest
          ? { post: existing, replayed: true as const, mentions: [] as string[], notifications: [] as Prisma.NotificationGetPayload<Record<string, never>>[] }
          : { conflict: true as const };

        let sourceAuthorId: string;
        let sourcePostAuthorId: string;
        if (options.sourcePostId) {
          const post = await tx.post.findFirst({ where: { id: options.sourcePostId, deletedAt: null, audience: StoryAudience.EVERYONE }, select: { userId: true } });
          if (!post) return { forbidden: true as const };
          sourceAuthorId = post.userId;
          sourcePostAuthorId = post.userId;
        } else if (options.sourceCommentId) {
          const comment = await tx.comment.findFirst({
            where: { id: options.sourceCommentId, deletedAt: null, isHidden: false, authorHiddenAt: null,
              post: { deletedAt: null, audience: StoryAudience.EVERYONE },
            },
            include: { post: { select: { userId: true } } },
          });
          if (!comment) return { forbidden: true as const };
          sourceAuthorId = comment.userId;
          sourcePostAuthorId = comment.post.userId;
        } else return { forbidden: true as const };

        const blocked = await tx.block.findFirst({ where: { OR: [
          { blockerId: options.userId, blockedId: sourceAuthorId }, { blockerId: sourceAuthorId, blockedId: options.userId },
          { blockerId: options.userId, blockedId: sourcePostAuthorId }, { blockerId: sourcePostAuthorId, blockedId: options.userId },
        ] }, select: { id: true } });
        if (blocked) return { forbidden: true as const };
        const mentionIds = options.mentionIds.filter((id) => id !== options.userId);
        const relationshipIds = [...new Set([options.userId, sourceAuthorId, sourcePostAuthorId])];
        const mentions = await tx.user.findMany({ where: { id: { in: mentionIds }, deletedAt: null,
          blocksGiven: { none: { blockedId: { in: relationshipIds } } },
          blocksReceived: { none: { blockerId: { in: relationshipIds } } },
        }, select: { id: true } });
        if (mentions.length !== mentionIds.length) return { invalidMention: true as const };
        const quotePostAuthor = await tx.user.findUniqueOrThrow({ where: { id: options.userId }, select: { displayName: true } });
        let post = await tx.post.create({
          data: {
            content: options.content, imageUrl: null, imageBlurHash: null,
            type: PostType.REGULAR, audience: StoryAudience.EVERYONE, isQuote: true,
            clientRequestId: options.requestId, clientRequestHash: options.digest,
            ...(options.sourcePostId ? { quoteSourcePost: { connect: { id: options.sourcePostId } } } : {}),
            ...(options.sourceCommentId ? { quoteSourceComment: { connect: { id: options.sourceCommentId } } } : {}),
            user: { connect: { id: options.userId } },
          }, include: POST_INCLUDE,
        });
        if (options.image) {
          imageUrl = saveUpload({ mimetype: options.image.mimeType, buffer: options.image.buffer }, 'post');
          post = await tx.post.update({
            where: { id: post.id },
            data: { imageUrl, imageBlurHash: options.imageBlurHash ?? null },
            include: POST_INCLUDE,
          });
        }
        let notifications: Prisma.NotificationGetPayload<Record<string, never>>[] = [];
        if (mentionIds.length) {
          await tx.postMention.createMany({ data: mentionIds.map((mentionedUserId) => ({ postId: post.id, mentionedUserId })), skipDuplicates: true });
          notifications = await tx.notification.createManyAndReturn({ data: mentionIds.map((userId) => ({ userId, type: NotificationType.MENTION, title: 'Nova menção', body: `@${quotePostAuthor.displayName} mencionou você em uma publicação`, data: { type: 'MENTION', action: 'post', postId: post.id } })), skipDuplicates: true });
        }
        return { post, replayed: false as const, mentions: mentionIds, notifications };
      });
      transactionCommitted = true;
      if ('conflict' in value) return left(new ConflictError('Idempotency key was already used with a different payload'));
      if ('forbidden' in value) return left(new ForbiddenError('A publicação de origem não está disponível'));
      if ('invalidMention' in value) return left(new BadRequestError('Mentioned user does not exist or is unavailable'));
      const post = (await normalizePostsForViewer([value.post], options.userId, this.prisma))[0];
      return right({
        post,
        mentionIds: value.mentions,
        notifications: value.notifications,
      });
    } catch (error) {
      if (imageUrl && !transactionCommitted) deleteUpload(imageUrl);
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        const existing = await this.prisma.post.findUnique({ where: { userId_clientRequestId: { userId: options.userId, clientRequestId: options.requestId } }, include: POST_INCLUDE }).catch(() => null);
        if (existing) return existing.clientRequestHash === options.digest
          ? right({ post: (await normalizePostsForViewer([existing], options.userId, this.prisma))[0], mentionIds: [], notifications: [] })
          : left(new ConflictError('Idempotency key was already used with a different payload'));
      }
      return left(new DatabaseError('Unable to create quote'));
    }
  }
}
