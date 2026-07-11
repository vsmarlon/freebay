import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CommentRepository } from '../../domain/repositories/comment.repository';
import { CommentFlatPayload, CommentPayload, COMMENT_FLAT_INCLUDE, COMMENT_INCLUDE } from '../../types/social.types';

@Injectable()
export class PrismaCommentRepository implements CommentRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAllByPostId(postId: string): RepositoryResponse<CommentFlatPayload[]> {
    try {
      const comments = await this.prisma.comment.findMany({
        where: { postId },
        orderBy: { createdAt: 'asc' },
        include: COMMENT_FLAT_INCLUDE,
      });
      return right(comments as CommentFlatPayload[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar comentários'));
    }
  }

  async create(data: Record<string, unknown>): RepositoryResponse<CommentPayload> {
    try {
      const comment = await this.prisma.comment.create({ data: data as Prisma.CommentCreateInput, include: COMMENT_INCLUDE });
      return right(comment as CommentPayload);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar comentário'));
    }
  }

  async createMentions(commentId: string, mentionedUserIds: string[]): RepositoryResponse<void> {
    try {
      await this.prisma.commentMention.createMany({
        data: mentionedUserIds.map((mentionedUserId) => ({ commentId, mentionedUserId })),
        skipDuplicates: true,
      });
      return right(undefined);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar menções no comentário'));
    }
  }
}
