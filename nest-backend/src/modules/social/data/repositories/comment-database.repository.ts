import { Injectable } from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from "@/shared/core/either";
import {
  CommentFlatPayload,
  CommentPayload,
  COMMENT_INCLUDE,
  commentPageIncludeForViewer,
  commentVisibilityWhere,
} from "../../types/social.types";
import { postVisibilityWhere } from './post-query-helpers';

@Injectable()
export class PrismaCommentRepository {
  constructor(private readonly prisma: PrismaService) {
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

  async approveHiddenComment(id: string, ownerId: string): RepositoryResponse<boolean> {
    return repositoryResponse(() => this.prisma.$transaction(async (tx) => {
      const approved = await tx.comment.updateMany({
        where: { id, deletedAt: null, isHidden: true, post: { userId: ownerId, deletedAt: null },
          OR: [{ parentId: null }, { parent: { isHidden: false, deletedAt: null } }],
        },
        data: { isHidden: false },
      });
      if (approved.count === 0) return false;
      const comment = await tx.comment.findUniqueOrThrow({ where: { id }, select: { postId: true } });
      await tx.post.update({ where: { id: comment.postId }, data: { commentsCount: { increment: 1 } } });
      return true;
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
            select: { postId: true, isHidden: true },
          });
          if (!comment) return false;

          const deleted = await tx.comment.updateMany({
            where: { id, deletedAt: null },
            data: { deletedAt: new Date() },
          });
          if (deleted.count === 0) return false;

          if (!comment.isHidden) {
            await tx.post.update({
              where: { id: comment.postId },
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
