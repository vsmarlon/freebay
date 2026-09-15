import { Injectable } from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { BasePrismaRepository } from "@/shared/infra/prisma/base-prisma.repository";
import { RepositoryResponse } from "@/shared/core/either";
import {
  CommentFlatPayload,
  CommentPayload,
  COMMENT_INCLUDE,
  commentPageIncludeForViewer,
} from "../../types/social.types";

@Injectable()
export class PrismaCommentRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findById(id: string): RepositoryResponse<CommentPayload | null> {
    return this.safeRun(async () => {
      const comment = await this.prisma.comment.findUnique({
        where: { id },
        include: COMMENT_INCLUDE,
      });
      if (comment && comment.deletedAt !== null) return null;
      return comment;
    }, "Erro ao buscar comentário");
  }

  async findAllByPostId(
    postId: string,
    viewerId?: string,
    limit = 20,
    offset = 0,
  ): RepositoryResponse<CommentFlatPayload[]> {
    return this.safeRun(async () => {
      const comments = await this.prisma.comment.findMany({
        where: { postId, parentId: null, deletedAt: null },
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
    data: Record<string, unknown>,
  ): RepositoryResponse<CommentPayload> {
    return this.safeRun(async () => {
      const comment = await this.prisma.comment.create({
        data: data as Prisma.CommentCreateInput,
        include: COMMENT_INCLUDE,
      });
      return comment;
    }, "Erro ao criar comentário");
  }

  async setCommentLike(
    userId: string,
    commentId: string,
    active: boolean,
  ): RepositoryResponse<void> {
    return this.safeRun(
      () =>
        this.prisma.$transaction(async (tx) => {
          if (active) {
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
            return;
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
        }),
      "Erro ao atualizar like do comentário",
    );
  }

  async createWithCount(
    data: Prisma.CommentCreateInput,
    postId: string,
  ): RepositoryResponse<CommentPayload> {
    return this.safeRun(
      () =>
        this.prisma.$transaction(async (tx) => {
          const comment = await tx.comment.create({
            data,
            include: COMMENT_INCLUDE,
          });
          await tx.post.update({
            where: { id: postId },
            data: { commentsCount: { increment: 1 } },
          });
          return comment;
        }),
      "Erro ao criar comentário",
    );
  }

  async createMentions(
    commentId: string,
    mentionedUserIds: string[],
  ): RepositoryResponse<void> {
    return this.safeRun(async () => {
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
    return this.safeRun(async () => {
      await this.prisma.comment.update({
        where: { id },
        data: { deletedAt: new Date() },
      });
    }, "Erro ao apagar comentário");
  }

  async softDeleteWithCount(id: string): RepositoryResponse<boolean> {
    return this.safeRun(
      () =>
        this.prisma.$transaction(async (tx) => {
          const comment = await tx.comment.findUnique({
            where: { id },
            select: { postId: true },
          });
          if (!comment) return false;

          const deleted = await tx.comment.updateMany({
            where: { id, deletedAt: null },
            data: { deletedAt: new Date() },
          });
          if (deleted.count === 0) return false;

          await tx.post.update({
            where: { id: comment.postId },
            data: { commentsCount: { decrement: 1 } },
          });
          return true;
        }),
      "Erro ao apagar comentário",
    );
  }

  async update(
    id: string,
    data: Record<string, unknown>,
  ): RepositoryResponse<unknown> {
    return this.safeRun(
      () =>
        this.prisma.comment.update({
          where: { id },
          data: data as Prisma.CommentUpdateInput,
        }),
      "Erro ao atualizar comentário",
    );
  }
}
