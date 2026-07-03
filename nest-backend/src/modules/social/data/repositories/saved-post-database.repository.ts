import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { SavedPostRepository } from '../../domain/repositories/saved-post.repository';

@Injectable()
export class PrismaSavedPostRepository implements SavedPostRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByUserAndPost(userId: string, postId: string): RepositoryResponse<{ id: string } | null> {
    try {
      const saved = await this.prisma.savedPost.findUnique({
        where: { userId_postId: { userId, postId } },
        select: { id: true },
      });
      return right(saved);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar post salvo'));
    }
  }

  async save(userId: string, postId: string): RepositoryResponse<{ id: string }> {
    try {
      const saved = await this.prisma.savedPost.create({
        data: { userId, postId },
        select: { id: true },
      });
      return right(saved);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao salvar post'));
    }
  }

  async unsave(userId: string, postId: string): RepositoryResponse<void> {
    try {
      await this.prisma.savedPost.delete({
        where: { userId_postId: { userId, postId } },
      });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao remover post salvo'));
    }
  }
}
