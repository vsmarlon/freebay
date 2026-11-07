import { Injectable } from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from "@/shared/core/either";
import {
  CommentFlatPayload,
  CommentPayload,
  COMMENT_INCLUDE,
  COMMENT_FLAT_INCLUDE,
  commentFlatIncludeForViewer,
  commentPageIncludeForViewer,
  commentVisibilityWhere,
} from "../../types/social.types";
import { postVisibilityWhere } from './post-query-helpers';
import { CommentCursor, CommentSort, encodeCommentCursor, CommentCursorScope } from '../../types/comment-cursor';
import { left, right } from '@/shared/core/either';
import { ConflictError, ForbiddenError, BadRequestError, DatabaseError } from '@/shared/core/errors';
import { CommentReplyPermission, NotificationType } from '@prisma/client';
import { deleteUpload, saveUpload } from '@/shared/utils/file.utils';

type CommentFlatRow = Prisma.CommentGetPayload<{ include: typeof COMMENT_FLAT_INCLUDE }>;

@Injectable()
export class CommentDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async createIdempotent(data: Prisma.CommentCreateInput, options: {
    postId: string; userId: string; requestId: string; digest: string; mentionIds: string[];
    media?: Array<{ buffer: Buffer; mimetype: string; size: number; sha256: string }>;
  }) {
    const writtenUrls: string[] = [];
    try {
      const value = await this.prisma.$transaction(async (tx) => {
        const post = await tx.post.findFirst({ where: { id: options.postId, deletedAt: null, AND: [postVisibilityWhere(options.userId)] }, select: { id: true, userId: true, replyPermission: true, audience: true } });
        if (!post) return { missing: true as const };
        if (post.audience === 'CLOSE_FRIENDS' && options.userId !== post.userId) {
          const [member, eligible, blocked] = await Promise.all([
            tx.closeFriend.findUnique({ where: { ownerId_memberId: { ownerId: post.userId, memberId: options.userId } }, select: { ownerId: true } }),
            tx.follow.findFirst({ where: { OR: [{ followerId: post.userId, followingId: options.userId }, { followerId: options.userId, followingId: post.userId }] }, select: { id: true } }),
            tx.block.findFirst({ where: { OR: [{ blockerId: post.userId, blockedId: options.userId }, { blockerId: options.userId, blockedId: post.userId }] }, select: { id: true } }),
          ]);
          if (!member || !eligible || blocked) return { forbidden: true as const };
        }
        const prior = await tx.comment.findUnique({ where: { userId_clientRequestId: { userId: options.userId, clientRequestId: options.requestId } }, include: COMMENT_INCLUDE });
        if (prior?.deletedAt) return { deleted: true as const };
        if (prior) return prior.clientRequestHash === options.digest
          ? { comment: prior, notifications: [], replayed: true }
          : { conflict: true as const };
        const parentId = data.parent?.connect?.id;
        const parent = parentId ? await tx.comment.findFirst({
          where: { id: parentId, postId: options.postId, deletedAt: null, AND: [commentVisibilityWhere(options.userId), { post: { deletedAt: null, AND: [postVisibilityWhere(options.userId)] } }] },
          select: { id: true, isHidden: true, userId: true },
        }) : null;
        if (parentId && !parent) return { invalidParent: true as const };
        if (post.replyPermission === 'CLOSED' && options.userId !== post.userId) return { forbidden: true as const };
        if (post.replyPermission === 'FOLLOWING' && options.userId !== post.userId) {
          const follows = await tx.follow.findUnique({ where: { followerId_followingId: { followerId: post.userId, followingId: options.userId } }, select: { id: true } });
          if (!follows) return { forbidden: true as const };
        }
        if (post.replyPermission === 'MENTIONED' && options.userId !== post.userId) {
          const mentioned = await tx.postMention.findUnique({ where: { postId_mentionedUserId: { postId: options.postId, mentionedUserId: options.userId } }, select: { id: true } });
          if (!mentioned) return { forbidden: true as const };
        }
        const validMentionIds = [...new Set(options.mentionIds)].filter((id) => id !== options.userId);
        const mentionUsers = await tx.user.findMany({ where: { id: { in: validMentionIds }, deletedAt: null }, select: { id: true } });
        if (mentionUsers.length !== validMentionIds.length) return { invalidMention: true as const };
        const restriction = await tx.restriction.findUnique({ where: { ownerId_restrictedId: { ownerId: post.userId, restrictedId: options.userId } }, select: { ownerId: true } });
        const isHidden = restriction !== null || parent?.isHidden === true;
        const comment = await tx.comment.create({
          data: { ...data, clientRequestId: options.requestId, clientRequestHash: options.digest, isHidden },
          include: COMMENT_INCLUDE,
        });
        for (const [position, media] of (options.media ?? []).entries()) {
          const url = saveUpload({ mimetype: media.mimetype, buffer: media.buffer }, 'comment');
          writtenUrls.push(url);
          await tx.commentMedia.create({ data: {
            commentId: comment.id,
            ownerId: options.userId,
            url,
            mimeType: media.mimetype,
            sha256: media.sha256,
            size: media.size,
            position,
          } });
        }
        if (validMentionIds.length) await tx.commentMention.createMany({ data: validMentionIds.map((mentionedUserId) => ({ commentId: comment.id, mentionedUserId })), skipDuplicates: true });
        const persistedComment = options.media?.length
          ? await tx.comment.findUniqueOrThrow({ where: { id: comment.id }, include: COMMENT_INCLUDE })
          : comment;
        if (isHidden) return { comment: persistedComment, notifications: [], replayed: false };

        await tx.post.update({ where: { id: options.postId }, data: { commentsCount: { increment: 1 } } });
        const subscriptionRows = await tx.commentSubscription.findMany({ where: { postId: options.postId }, select: { userId: true } });
        const recipientIds = new Set([post.userId, ...(parent ? [parent.userId] : []), ...validMentionIds, ...subscriptionRows.map((row) => row.userId)]);
        recipientIds.delete(options.userId);
        const mutes = await tx.commentConversationMute.findMany({ where: { postId: options.postId, userId: { in: [...recipientIds] } }, select: { userId: true } });
        for (const mute of mutes) recipientIds.delete(mute.userId);
        const restrictedRecipients = await tx.restriction.findMany({ where: { ownerId: { in: [...recipientIds] }, restrictedId: options.userId }, select: { ownerId: true } });
        for (const restriction of restrictedRecipients) recipientIds.delete(restriction.ownerId);
        if (post.audience === 'CLOSE_FRIENDS') {
          const allowed = await tx.closeFriend.findMany({ where: { ownerId: post.userId, memberId: { in: [...recipientIds] } }, select: { memberId: true } });
          const allowedIds = new Set(allowed.map((row) => row.memberId));
          const connected = await tx.follow.findMany({ where: { OR: [
            { followerId: post.userId, followingId: { in: [...allowedIds] } },
            { followingId: post.userId, followerId: { in: [...allowedIds] } },
          ] }, select: { followerId: true, followingId: true } });
          const eligibleIds = new Set(connected.flatMap((edge) => edge.followerId === post.userId ? [edge.followingId] : [edge.followerId]));
          for (const id of allowedIds) if (!eligibleIds.has(id)) allowedIds.delete(id);
          for (const id of recipientIds) if (!allowedIds.has(id)) recipientIds.delete(id);
        }
        const blocked = await tx.block.findMany({ where: { OR: [
          { blockerId: options.userId, blockedId: { in: [...recipientIds] } },
          { blockedId: options.userId, blockerId: { in: [...recipientIds] } },
          { blockerId: post.userId, blockedId: { in: [...recipientIds] } },
          { blockedId: post.userId, blockerId: { in: [...recipientIds] } },
        ] }, select: { blockerId: true, blockedId: true } });
        for (const block of blocked) {
          if (block.blockerId === options.userId || block.blockerId === post.userId) recipientIds.delete(block.blockedId);
          else recipientIds.delete(block.blockerId);
        }
        const inserted = recipientIds.size ? await tx.notification.createManyAndReturn({ data: [...recipientIds].map((userId) => ({
          userId, type: NotificationType.MENTION, title: 'Nova resposta', body: 'Há uma nova resposta na conversa',
          data: { type: 'MENTION', action: 'comment', postId: options.postId, commentId: comment.id },
          commentId: comment.id, dedupeKey: `comment:${comment.id}:reply:${userId}`,
        })), skipDuplicates: true }) : [];
        return { comment: persistedComment, notifications: inserted, replayed: false };
      });
      if ('conflict' in value) return left(new ConflictError('Idempotency key was already used with a different payload'));
      if ('deleted' in value) return left(new BadRequestError('Comment is no longer available'));
      if ('missing' in value) return left(new BadRequestError('Post is not available'));
      if ('invalidParent' in value) return left(new BadRequestError('Invalid parent comment'));
      if ('forbidden' in value) return left(new ForbiddenError('Replies are closed or restricted for this conversation'));
      if ('invalidMention' in value) return left(new BadRequestError('Mentioned user does not exist'));
      return right(value);
    } catch (error) {
      for (const url of writtenUrls) deleteUpload(url);
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        const prior = await this.prisma.comment.findUnique({ where: { userId_clientRequestId: { userId: options.userId, clientRequestId: options.requestId } }, include: COMMENT_INCLUDE }).catch(() => null);
        if (prior?.deletedAt) return left(new BadRequestError('Comment is no longer available'));
        if (prior) return prior.clientRequestHash === options.digest
          ? right({ comment: prior, notifications: [], replayed: true })
          : left(new ConflictError('Idempotency key was already used with a different payload'));
      }
      return left(new DatabaseError('Unable to create comment'));
    }
  }

  async findConversationPage(postId: string, viewerId: string, limit: number, sort: CommentSort, cursor?: CommentCursor) {
    return repositoryResponse(async () => {
      const orderBy: Prisma.CommentOrderByWithRelationInput[] = sort === CommentSort.RECENT
        ? [{ createdAt: 'desc' }, { id: 'desc' }]
        : [{ likesCount: 'desc' }, { createdAt: 'desc' }, { id: 'desc' }];
      const after = cursor ? sort === CommentSort.RECENT ? {
        OR: [{ createdAt: { lt: new Date(cursor.createdAt) } }, { createdAt: new Date(cursor.createdAt), id: { lt: cursor.id } }],
      } : {
        OR: [
          { likesCount: { lt: cursor.likesCount } },
          { likesCount: cursor.likesCount, createdAt: { lt: new Date(cursor.createdAt) } },
          { likesCount: cursor.likesCount, createdAt: new Date(cursor.createdAt), id: { lt: cursor.id } },
        ],
      } : {};
      const rows = await this.prisma.comment.findMany({
        where: { postId, parentId: null, OR: [{ deletedAt: null }, { replies: { some: { deletedAt: null } } }], AND: [commentVisibilityWhere(viewerId), { post: { deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }, after] },
        orderBy, take: limit + 1, include: commentPageIncludeForViewer(viewerId),
      });
      const hasMore = rows.length > limit;
      const page = rows.slice(0, limit);
      const last = page.at(-1);
      return {
        items: page.map(({ replies, commentLikes, ...root }) => {
          const { clientRequestId: _requestId, clientRequestHash: _requestHash, ...publicRoot } = root;
          const { userId: _deletedUserId, ...tombstoneRoot } = publicRoot;
          return {
          ...(root.deletedAt ? tombstoneRoot : publicRoot),
          content: root.deletedAt ? null : root.content,
          user: root.deletedAt ? null : root.user,
           likesCount: root.deletedAt ? 0 : root.likesCount,
           _count: root.deletedAt ? { commentLikes: 0 } : root._count,
           isLiked: !root.deletedAt && commentLikes.length > 0,
           media: root.deletedAt ? [] : root.media,
           replies: replies.map(({ commentLikes, ...reply }) => {
             const { clientRequestId: _replyRequestId, clientRequestHash: _replyRequestHash, ...publicReply } = reply;
             const { userId: _deletedReplyUserId, ...replyTombstone } = publicReply;
             return { ...(reply.deletedAt ? replyTombstone : publicReply), content: reply.deletedAt ? null : reply.content, user: reply.deletedAt ? null : reply.user, likesCount: reply.deletedAt ? 0 : reply.likesCount, media: reply.deletedAt ? [] : reply.media, isLiked: !reply.deletedAt && commentLikes.length > 0 };
          }),
        }; }),
        nextCursor: hasMore && last ? encodeCommentCursor({
          scope: CommentCursorScope.CONVERSATION, ownerId: postId, viewerId, sort, id: last.id,
          createdAt: last.createdAt.toISOString(), likesCount: last.likesCount,
        }) : null,
      };
    }, 'Erro ao carregar conversa');
  }

  async setAuthorHidden(commentId: string, postAuthorId: string, hidden: boolean): RepositoryResponse<boolean> {
    return repositoryResponse(() => this.prisma.$transaction(async (tx) => {
      const current = await tx.comment.findFirst({ where: { id: commentId, post: { userId: postAuthorId, deletedAt: null } }, select: { postId: true, isHidden: true, deletedAt: true, authorHiddenAt: true } });
      if (!current) return false;
      if (hidden ? current.authorHiddenAt !== null : current.authorHiddenAt === null) return true;
      const changed = await tx.comment.updateMany({
        where: { id: commentId, post: { userId: postAuthorId }, authorHiddenAt: hidden ? null : { not: null } },
        data: { authorHiddenAt: hidden ? new Date() : null },
      });
      if (!changed.count) return false;
      if (!current.isHidden && current.deletedAt === null) {
        if (hidden) await tx.post.updateMany({ where: { id: current.postId, commentsCount: { gt: 0 } }, data: { commentsCount: { decrement: 1 } } });
        else await tx.post.update({ where: { id: current.postId }, data: { commentsCount: { increment: 1 } } });
      }
      return true;
    }), 'Erro ao atualizar visibilidade da resposta');
  }

  async setReplyPermission(postId: string, postAuthorId: string, permission: CommentReplyPermission): RepositoryResponse<boolean> {
    return repositoryResponse(async () => (await this.prisma.post.updateMany({
      where: { id: postId, userId: postAuthorId, deletedAt: null }, data: { replyPermission: permission },
    })).count > 0, 'Erro ao atualizar permissão de respostas');
  }

  async setConversationPreference(postId: string, userId: string, enabled: boolean, mute: boolean): RepositoryResponse<boolean> {
    return repositoryResponse(() => this.prisma.$transaction(async (tx) => {
      const post = await tx.post.findFirst({ where: { id: postId, deletedAt: null, AND: [postVisibilityWhere(userId)] }, select: { id: true } });
      if (!post) return false;
      const where = { userId_postId: { userId, postId } };
      if (mute) {
        if (enabled) await tx.commentConversationMute.upsert({ where, create: { userId, postId }, update: {} });
        else await tx.commentConversationMute.deleteMany({ where: { userId, postId } });
      } else if (enabled) {
        await tx.commentSubscription.upsert({ where, create: { userId, postId }, update: {} });
      } else {
        await tx.commentSubscription.deleteMany({ where: { userId, postId } });
      }
      return true;
    }), 'Erro ao atualizar preferências da conversa');
  }

  async findAuthorHidden(postId: string, viewerId: string, limit: number, cursor?: { createdAt: Date; id: string }) {
    return repositoryResponse(async () => {
      const rows = await this.prisma.comment.findMany({
        where: { postId, authorHiddenAt: { not: null }, isHidden: false, deletedAt: null,
          AND: [{ post: { deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }, ...(cursor ? [{ OR: [{ createdAt: { lt: cursor.createdAt } }, { createdAt: cursor.createdAt, id: { lt: cursor.id } }] }] : [])] },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1, include: commentFlatIncludeForViewer(viewerId),
      });
      const hasMore = rows.length > limit;
      const items = rows.slice(0, limit).map(({ commentLikes, ...comment }) => {
        const { clientRequestId: _requestId, clientRequestHash: _requestHash, ...publicComment } = comment;
        return { ...publicComment, isLiked: commentLikes.length > 0 };
      });
      const last = items.at(-1);
      return { items, nextCursor: hasMore && last ? Buffer.from(JSON.stringify({ postId, viewerId, createdAt: last.createdAt.toISOString(), id: last.id })).toString('base64url') : null };
    }, 'Erro ao buscar respostas ocultas');
  }

  async findCommentContext(commentId: string, viewerId: string, replyLimit: number, sort: CommentSort, replyCursor?: CommentCursor, ancestorCursor?: CommentCursor) {
    return repositoryResponse(async () => {
      const focus = await this.prisma.comment.findFirst({
        where: { id: commentId, AND: [commentVisibilityWhere(viewerId), { post: { deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }] },
        include: { ...commentFlatIncludeForViewer(viewerId), post: { select: { id: true } } },
      });
      if (!focus) return null;
      const orderBy: Prisma.CommentOrderByWithRelationInput[] = sort === CommentSort.RECENT
        ? [{ createdAt: 'desc' }, { id: 'desc' }]
        : [{ likesCount: 'desc' }, { createdAt: 'desc' }, { id: 'desc' }];
      const after = replyCursor ? sort === CommentSort.RECENT ? {
        OR: [{ createdAt: { lt: new Date(replyCursor.createdAt) } }, { createdAt: new Date(replyCursor.createdAt), id: { lt: replyCursor.id } }],
      } : {
        OR: [
          { likesCount: { lt: replyCursor.likesCount } },
          { likesCount: replyCursor.likesCount, createdAt: { lt: new Date(replyCursor.createdAt) } },
          { likesCount: replyCursor.likesCount, createdAt: new Date(replyCursor.createdAt), id: { lt: replyCursor.id } },
        ],
      } : {};
      const replyRows = await this.prisma.comment.findMany({
        where: { parentId: commentId, deletedAt: null, AND: [commentVisibilityWhere(viewerId), { post: { deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }, after] },
        orderBy, take: replyLimit + 1, include: commentFlatIncludeForViewer(viewerId),
      });
      const hasMoreReplies = replyRows.length > replyLimit;
      const replies = replyRows.slice(0, replyLimit);
      const lastReply = replies.at(-1);
      const ancestors: Array<Record<string, unknown>> = [];
      let nextAncestorId: string | null = null;
      if (ancestorCursor) {
        let pathId = focus.parentId;
        let cursorIsAncestor = false;
        while (pathId) {
          const pathNode = await this.prisma.comment.findFirst({
            where: { id: pathId, AND: [commentVisibilityWhere(viewerId), { post: { id: focus.postId, deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }] },
            select: { id: true, parentId: true },
          });
          if (!pathNode) break;
          if (pathNode.id === ancestorCursor.id) {
            cursorIsAncestor = true;
            break;
          }
          pathId = pathNode.parentId;
        }
        if (!cursorIsAncestor) return null;
      }
      let anchorId = ancestorCursor?.id ?? focus.parentId;
      const ancestorPage: CommentFlatRow[] = [];
      let skipCursorAnchor = ancestorCursor !== undefined;
      while (anchorId && ancestorPage.length < 33) {
        const ancestor = await this.prisma.comment.findFirst({
          where: { id: anchorId, AND: [commentVisibilityWhere(viewerId), { post: { id: focus.postId, deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }] },
          include: commentFlatIncludeForViewer(viewerId),
        });
        if (!ancestor) break;
        if (skipCursorAnchor) skipCursorAnchor = false;
        else ancestorPage.push(ancestor);
        anchorId = ancestor.parentId;
      }
      const hasMoreAncestors = ancestorPage.length > 32;
      const visibleAncestors = ancestorPage.slice(0, 32).reverse();
      ancestors.push(...visibleAncestors.map(({ commentLikes, ...ancestor }) => {
        const { clientRequestId: _requestId, clientRequestHash: _requestHash, ...publicAncestor } = ancestor;
        const { userId: _deletedUserId, ...tombstone } = publicAncestor;
        return { ...(ancestor.deletedAt ? tombstone : publicAncestor), content: ancestor.deletedAt ? null : ancestor.content, user: ancestor.deletedAt ? null : ancestor.user, likesCount: ancestor.deletedAt ? 0 : ancestor.likesCount, media: ancestor.deletedAt ? [] : ancestor.media, _count: ancestor.deletedAt ? { commentLikes: 0 } : ancestor._count, isLiked: !ancestor.deletedAt && commentLikes.length > 0 };
      }));
      if (hasMoreAncestors) nextAncestorId = ancestorPage[31]?.id ?? null;
      const { commentLikes: focusLikes, ...focusFields } = focus;
      const { clientRequestId: _focusRequestId, clientRequestHash: _focusRequestHash, ...publicFocus } = focusFields;
      const { userId: _deletedFocusUserId, ...focusTombstone } = publicFocus;
      const focusView = { ...(focus.deletedAt ? focusTombstone : publicFocus), content: focus.deletedAt ? null : focus.content, user: focus.deletedAt ? null : focus.user, likesCount: focus.deletedAt ? 0 : focus.likesCount, _count: focus.deletedAt ? { commentLikes: 0 } : focus._count, isLiked: !focus.deletedAt && focusLikes.length > 0, media: focus.deletedAt ? [] : focus.media };
      return {
        ancestors,
        focus: focusView,
        replies: replies.map(({ commentLikes, ...reply }) => {
          const { clientRequestId: _requestId, clientRequestHash: _requestHash, ...publicReply } = reply;
          const { userId: _deletedUserId, ...tombstone } = publicReply;
          return { ...(reply.deletedAt ? tombstone : publicReply), isLiked: !reply.deletedAt && commentLikes.length > 0, content: reply.deletedAt ? null : reply.content, user: reply.deletedAt ? null : reply.user, likesCount: reply.deletedAt ? 0 : reply.likesCount, media: reply.deletedAt ? [] : reply.media };
        }),
        nextReplyCursor: hasMoreReplies && lastReply ? encodeCommentCursor({
          scope: CommentCursorScope.CONTEXT_REPLIES, ownerId: commentId, viewerId, sort, id: lastReply.id,
          createdAt: lastReply.createdAt.toISOString(), likesCount: lastReply.likesCount,
        }) : null,
        nextAncestorCursor: nextAncestorId ? encodeCommentCursor({
          scope: CommentCursorScope.CONTEXT_ANCESTORS, ownerId: commentId, viewerId, sort: CommentSort.RECENT, id: nextAncestorId,
          createdAt: ancestorPage[31]?.createdAt instanceof Date ? ancestorPage[31].createdAt.toISOString() : '',
          likesCount: 0,
        }) : null,
      };
    }, 'Erro ao carregar contexto do comentário');
  }

  async findById(id: string): RepositoryResponse<CommentPayload | null> {
    return repositoryResponse(async () => {
      const comment = await this.prisma.comment.findUnique({
        where: { id },
        include: COMMENT_INCLUDE,
      });
      if (comment && comment.deletedAt !== null) return null;
      return comment;
    }, "Erro ao buscar comentário");
  }

  async belongsToPost(parentId: string, postId: string, viewerId: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const parent = await this.prisma.comment.findFirst({
        where: { id: parentId, postId, deletedAt: null,
          AND: [commentVisibilityWhere(viewerId), { post: { deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }],
        },
        select: { id: true },
      });
      return parent !== null;
    }, 'Erro ao verificar comentário pai');
  }

  async findAllByPostId(
    postId: string,
    viewerId?: string,
    limit = 20,
    offset = 0,
  ): RepositoryResponse<CommentFlatPayload[]> {
    return repositoryResponse(async () => {
      const comments = await this.prisma.comment.findMany({
        where: { postId, parentId: null, deletedAt: null,
          AND: [commentVisibilityWhere(viewerId), { post: { deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }],
        },
        orderBy: { createdAt: "asc" },
        take: limit,
        skip: offset,
        include: commentPageIncludeForViewer(viewerId),
      });
      return comments
        .flatMap(({ replies, ...comment }) => [comment, ...replies])
        .map(({ commentLikes, ...comment }) => ({
          ...comment,
          isLiked: commentLikes.length > 0,
        }));
    }, "Erro ao buscar comentários");
  }

  async create(
    data: Prisma.CommentCreateInput,
  ): RepositoryResponse<CommentPayload> {
    return repositoryResponse(async () => {
      const comment = await this.prisma.comment.create({
        data,
        include: COMMENT_INCLUDE,
      });
      return comment;
    }, "Erro ao criar comentário");
  }

  async setCommentLike(
    userId: string,
    commentId: string,
    active: boolean,
  ): RepositoryResponse<boolean> {
    return repositoryResponse(
      () =>
        this.prisma.$transaction(async (tx) => {
          if (active) {
            const visible = await tx.comment.findFirst({
              where: { id: commentId, deletedAt: null,
                AND: [commentVisibilityWhere(userId), { post: { deletedAt: null, AND: [postVisibilityWhere(userId)] } }],
              },
              select: { id: true },
            });
            if (!visible) return false;
            const created = await tx.commentLike.createMany({
              data: { userId, commentId },
              skipDuplicates: true,
            });
            if (created.count > 0) {
              await tx.comment.update({
                where: { id: commentId },
                data: { likesCount: { increment: 1 } },
              });
            }
            return true;
          }

          const deleted = await tx.commentLike.deleteMany({
            where: { userId, commentId },
          });
          if (deleted.count > 0) {
            await tx.comment.updateMany({
              where: { id: commentId, likesCount: { gt: 0 } },
              data: { likesCount: { decrement: 1 } },
            });
          }
          return true;
        }),
      "Erro ao atualizar like do comentário",
    );
  }

  async createWithCount(
    data: Prisma.CommentCreateInput,
    postId: string,
    postOwnerId: string,
    commenterId: string,
  ): RepositoryResponse<CommentPayload> {
    return repositoryResponse(
      () =>
        this.prisma.$transaction(async (tx) => {
          const restricted = await tx.restriction.findUnique({
            where: { ownerId_restrictedId: { ownerId: postOwnerId, restrictedId: commenterId } },
            select: { ownerId: true },
          });
          const parentId = data.parent?.connect?.id;
          const parent = parentId
            ? await tx.comment.findUnique({ where: { id: parentId }, select: { isHidden: true } })
            : null;
          const isHidden = restricted !== null || parent?.isHidden === true;
          const comment = await tx.comment.create({
            data: { ...data, isHidden },
            include: COMMENT_INCLUDE,
          });
          if (!isHidden) {
            await tx.post.update({
              where: { id: postId },
              data: { commentsCount: { increment: 1 } },
            });
          }
          return comment;
        }),
      "Erro ao criar comentário",
    );
  }

  async approveHiddenComment(id: string, ownerId: string): RepositoryResponse<{ approved: boolean; notifications: Array<{ userId: string; id: string; type: NotificationType; data: Prisma.JsonValue | null }> }> {
    return repositoryResponse(() => this.prisma.$transaction(async (tx) => {
      const approved = await tx.comment.updateMany({
        where: { id, deletedAt: null, isHidden: true, post: { userId: ownerId, deletedAt: null },
          OR: [{ parentId: null }, { parent: { isHidden: false, deletedAt: null } }],
        },
        data: { isHidden: false },
      });
      if (approved.count === 0) return { approved: false, notifications: [] };
      const comment = await tx.comment.findUniqueOrThrow({ where: { id }, select: { id: true, postId: true, userId: true, parentId: true, authorHiddenAt: true, mentions: { select: { mentionedUserId: true } }, post: { select: { userId: true, audience: true } } } });
      if (comment.authorHiddenAt !== null) return { approved: true, notifications: [] };
      await tx.post.update({ where: { id: comment.postId }, data: { commentsCount: { increment: 1 } } });
      const parent = comment.parentId ? await tx.comment.findUnique({ where: { id: comment.parentId }, select: { userId: true } }) : null;
      const subscriptions = await tx.commentSubscription.findMany({ where: { postId: comment.postId }, select: { userId: true } });
      const recipients = new Set([comment.post.userId, ...(parent ? [parent.userId] : []), ...comment.mentions.map(({ mentionedUserId }) => mentionedUserId), ...subscriptions.map(({ userId }) => userId)]);
      recipients.delete(comment.userId);
      const mutes = await tx.commentConversationMute.findMany({ where: { postId: comment.postId, userId: { in: [...recipients] } }, select: { userId: true } });
      for (const row of mutes) recipients.delete(row.userId);
      if (comment.post.audience === 'CLOSE_FRIENDS') {
        const members = await tx.closeFriend.findMany({ where: { ownerId: comment.post.userId, memberId: { in: [...recipients] } }, select: { memberId: true } });
        const allowed = new Set(members.map(({ memberId }) => memberId));
        const connected = await tx.follow.findMany({ where: { OR: [
          { followerId: comment.post.userId, followingId: { in: [...allowed] } },
          { followingId: comment.post.userId, followerId: { in: [...allowed] } },
        ] }, select: { followerId: true, followingId: true } });
        const eligible = new Set(connected.map((edge) => edge.followerId === comment.post.userId ? edge.followingId : edge.followerId));
        for (const id of allowed) if (!eligible.has(id)) allowed.delete(id);
        for (const recipient of recipients) if (!allowed.has(recipient)) recipients.delete(recipient);
      }
      const blocks = await tx.block.findMany({ where: { OR: [
        { blockerId: comment.userId, blockedId: { in: [...recipients] } },
        { blockedId: comment.userId, blockerId: { in: [...recipients] } },
        { blockerId: comment.post.userId, blockedId: { in: [...recipients] } },
        { blockedId: comment.post.userId, blockerId: { in: [...recipients] } },
      ] }, select: { blockerId: true, blockedId: true } });
      for (const block of blocks) {
        if (block.blockerId === comment.userId || block.blockerId === comment.post.userId) recipients.delete(block.blockedId);
        else recipients.delete(block.blockerId);
      }
      const notifications = recipients.size ? await tx.notification.createManyAndReturn({ data: [...recipients].map((userId) => ({
        userId, type: NotificationType.MENTION, title: 'Nova resposta', body: 'Há uma nova resposta na conversa',
        data: { type: 'MENTION', action: 'comment', postId: comment.postId, commentId: comment.id },
        commentId: comment.id, dedupeKey: `comment:${comment.id}:reply:${userId}`,
      })), skipDuplicates: true }) : [];
      return { approved: true, notifications };
    }), 'Erro ao aprovar comentário');
  }

  async createMentions(
    commentId: string,
    mentionedUserIds: string[],
  ): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.commentMention.createMany({
        data: mentionedUserIds.map((mentionedUserId) => ({
          commentId,
          mentionedUserId,
        })),
        skipDuplicates: true,
      });
    }, "Erro ao criar menções no comentário");
  }

  async softDelete(id: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.comment.update({
        where: { id },
        data: { deletedAt: new Date() },
      });
    }, "Erro ao apagar comentário");
  }

  async softDeleteWithCount(id: string): RepositoryResponse<boolean> {
    return repositoryResponse(
      () =>
        this.prisma.$transaction(async (tx) => {
          const comment = await tx.comment.findUnique({
            where: { id },
            select: { postId: true, isHidden: true, authorHiddenAt: true },
          });
          if (!comment) return false;

          const deleted = await tx.comment.updateMany({
            where: { id, deletedAt: null },
            data: { deletedAt: new Date() },
          });
          if (deleted.count === 0) return false;

          if (!comment.isHidden && comment.authorHiddenAt === null) {
            await tx.post.updateMany({
              where: { id: comment.postId, commentsCount: { gt: 0 } },
              data: { commentsCount: { decrement: 1 } },
            });
          }
          return true;
        }),
      "Erro ao apagar comentário",
    );
  }

  async update(
    id: string,
    data: Prisma.CommentUpdateInput,
  ): RepositoryResponse<unknown> {
    return repositoryResponse(
      () =>
        this.prisma.comment.update({
          where: { id },
          data,
        }),
      "Erro ao atualizar comentário",
    );
  }
}
