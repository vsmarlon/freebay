import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { SavedPostRepository } from '../../domain/repositories/saved-post.repository';

@Injectable()
export class PrismaSavedPostRepository extends BasePrismaRepository implements SavedPostRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findByUserAndPost(userId: string, postId: string): RepositoryResponse<{ id: string } | null> {
    return this.safeRun(() => this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId, postId } },
      select: { id: true },
    }), 'Erro ao buscar post salvo');
  }

  async save(userId: string, postId: string): RepositoryResponse<{ id: string }> {
    return this.safeRun(() => this.prisma.savedPost.create({
      data: { userId, postId },
      select: { id: true },
    }), 'Erro ao salvar post');
  }

  async unsave(userId: string, postId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.savedPost.delete({ where: { userId_postId: { userId, postId } } });
    }, 'Erro ao remover post salvo');
  }
}
