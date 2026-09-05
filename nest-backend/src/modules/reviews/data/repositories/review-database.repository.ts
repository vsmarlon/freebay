import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { Prisma, ReviewType } from '@prisma/client';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { ReviewRepository } from '@/modules/reviews/domain/repositories/review.repository';
import { REVIEW_INCLUDE, REVIEW_DETAILED_INCLUDE, ReviewWithReviewer, ReviewWithDetails } from '@/modules/reviews/types/review.types';
import { RepositoryResponse } from '@/shared/core/either';
import { saveUpload } from '@/shared/utils/file.utils';

@Injectable()
export class PrismaReviewRepository extends BasePrismaRepository implements ReviewRepository {
  async findById(id: string): RepositoryResponse<ReviewWithDetails | null> {
    return this.safeRun(() => this.prisma.review.findUnique({
      where: { id },
      include: REVIEW_DETAILED_INCLUDE,
    }), 'Erro ao buscar avaliação');
  }

  async findByReviewedId(
    reviewedId: string,
    options?: { offset?: number; limit?: number; type?: ReviewType },
  ): RepositoryResponse<{
    reviews: ReviewWithReviewer[];
    total: number;
    offset: number;
    limit: number;
  }> {
    return this.safeRun(async () => {
      const offset = options?.offset ?? 0;
      const limit = options?.limit ?? 10;
      const where: Prisma.ReviewWhereInput = {
        reviewedId,
        ...(options?.type && { type: options.type }),
      };
      const [reviews, total] = await Promise.all([
        this.prisma.review.findMany({
          where,
          skip: offset,
          take: limit,
          orderBy: { createdAt: 'desc' },
          include: REVIEW_INCLUDE,
        }),
        this.prisma.review.count({ where }),
      ]);
      return { reviews, total, offset, limit };
    }, 'Erro ao listar avaliações');
  }

  async findByOrderAndType(orderId: string, type: ReviewType): RepositoryResponse<ReviewWithReviewer | null> {
    return this.safeRun(async () => {
      return await this.prisma.review.findFirst({ where: { orderId, type }, include: REVIEW_INCLUDE });
    }, 'Erro ao buscar avaliação');
  }

  async findExistingReview(reviewerId: string, orderId: string, type: ReviewType): RepositoryResponse<ReviewWithReviewer | null> {
    return this.safeRun(async () => {
      return await this.prisma.review.findUnique({
        where: { reviewerId_orderId_type: { reviewerId, orderId, type } },
        include: REVIEW_INCLUDE,
      });
    }, 'Erro ao buscar avaliação existente');
  }

  async create(data: Prisma.ReviewCreateInput): RepositoryResponse<ReviewWithReviewer> {
    return this.safeRun(async () => {
      return await this.prisma.review.create({ data, include: REVIEW_INCLUDE });
    }, 'Erro ao criar avaliação');
  }

  async updateUserReputation(userId: string): RepositoryResponse<{ reputationScore: number; totalReviews: number }> {
    return this.safeRun(async () => {
      const [averageScore, totalReviews] = await Promise.all([
        this.prisma.review.aggregate({ where: { reviewedId: userId }, _avg: { score: true } }),
        this.prisma.review.count({ where: { reviewedId: userId } }),
      ]);
      const reputationScore = averageScore._avg.score ?? 0;
      await this.prisma.user.update({
        where: { id: userId },
        data: { reputationScore, totalReviews },
      });
      return { reputationScore, totalReviews };
    }, 'Erro ao atualizar reputação');
  }

  async uploadImage(file: { buffer: Buffer; mimetype: string }): RepositoryResponse<{ imageId: string; url: string }> {
    return this.safeRun(async () => {
      const imageId = uuidv4();
      const url = saveUpload(file, 'review');
      return { imageId, url };
    }, 'Erro ao processar imagem');
  }
}
