import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { CommentRepository } from '../../domain/repositories/comment.repository';
import { CommentFlatPayload, CommentPayload, COMMENT_FLAT_INCLUDE, COMMENT_INCLUDE } from '../../types/social.types';

@Injectable()
export class PrismaCommentRepository extends BasePrismaRepository implements CommentRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAllByPostId(postId: string): RepositoryResponse<CommentFlatPayload[]> {
    return this.safeRun(async () => {
      const comments = await this.prisma.comment.findMany({
        where: { postId },
        orderBy: { createdAt: 'asc' },
        include: COMMENT_FLAT_INCLUDE,
      });
      return comments as CommentFlatPayload[];
    }, 'Erro ao buscar comentários');
  }

  async create(data: Record<string, unknown>): RepositoryResponse<CommentPayload> {
    return this.safeRun(async () => {
      const comment = await this.prisma.comment.create({
        data: data as Prisma.CommentCreateInput,
        include: COMMENT_INCLUDE,
      });
      return comment as CommentPayload;
    }, 'Erro ao criar comentário');
  }

  async createMentions(commentId: string, mentionedUserIds: string[]): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.commentMention.createMany({
        data: mentionedUserIds.map((mentionedUserId) => ({ commentId, mentionedUserId })),
        skipDuplicates: true,
      });
    }, 'Erro ao criar menções no comentário');
  }
}
