import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CommentRepository } from '../../domain/repositories/comment.repository';
import { CommentPayload, COMMENT_INCLUDE } from '../../types/social.types';

@Injectable()
export class PrismaCommentRepository implements CommentRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByPostId(postId: string, params: { limit?: number; offset?: number }): RepositoryResponse<CommentPayload[]> {
    try {
      const comments = await this.prisma.comment.findMany({
        where: { postId, parentId: null },
        orderBy: { createdAt: 'desc' },
        take: params.limit ?? 20,
        skip: params.offset ?? 0,
        include: COMMENT_INCLUDE,
      });
      return right(comments as CommentPayload[]);
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
}
