import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { Prisma, ReviewType } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ReviewRepository, REVIEW_INCLUDE, REVIEW_DETAILED_INCLUDE, ReviewWithReviewer, ReviewWithDetails } from '@/modules/reviews/domain/repositories/review.repository';
import { right, left, RepositoryResponse } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@Injectable()
export class PrismaReviewRepository extends ReviewRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async findById(id: string): RepositoryResponse<ReviewWithDetails | null> {
    try {
      const review = await this.prisma.review.findUnique({
        where: { id },
        include: REVIEW_DETAILED_INCLUDE,
      });
      return right(review);
    } catch {
      return left(new AppError('DATABASE_ERROR', 'Erro ao buscar avaliação', 500));
    }
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
    try {
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

      return right({ reviews: reviews as unknown as ReviewWithReviewer[], total, offset, limit });
    } catch {
      return left(new AppError('DATABASE_ERROR', 'Erro ao listar avaliações', 500));
    }
  }

  async findByOrderAndType(
    orderId: string,
    type: ReviewType,
  ): RepositoryResponse<ReviewWithReviewer | null> {
    try {
      const review = await this.prisma.review.findFirst({
        where: { orderId, type },
        include: REVIEW_INCLUDE,
      });
      return right(review as unknown as ReviewWithReviewer | null);
    } catch {
      return left(new AppError('DATABASE_ERROR', 'Erro ao buscar avaliação', 500));
    }
  }

  async findExistingReview(
    reviewerId: string,
    orderId: string,
    type: ReviewType,
  ): RepositoryResponse<ReviewWithReviewer | null> {
    try {
      const review = await this.prisma.review.findUnique({
        where: {
          reviewerId_orderId_type: { reviewerId, orderId, type },
        },
        include: REVIEW_INCLUDE,
      });
      return right(review as unknown as ReviewWithReviewer | null);
    } catch {
      return left(new AppError('DATABASE_ERROR', 'Erro ao buscar avaliação existente', 500));
    }
  }

  async create(data: Prisma.ReviewCreateInput): RepositoryResponse<ReviewWithReviewer> {
    try {
      const review = await this.prisma.review.create({
        data,
        include: REVIEW_INCLUDE,
      });
      return right(review as unknown as ReviewWithReviewer);
    } catch {
      return left(new AppError('DATABASE_ERROR', 'Erro ao criar avaliação', 500));
    }
  }

  async updateUserReputation(
    userId: string,
  ): RepositoryResponse<{ reputationScore: number; totalReviews: number }> {
    try {
      const [averageScore, totalReviews] = await Promise.all([
        this.prisma.review.aggregate({
          where: { reviewedId: userId },
          _avg: { score: true },
        }),
        this.prisma.review.count({
          where: { reviewedId: userId },
        }),
      ]);

      const reputationScore = averageScore._avg.score ?? 0;

      await this.prisma.user.update({
        where: { id: userId },
        data: { reputationScore, totalReviews },
      });

      return right({ reputationScore, totalReviews });
    } catch {
      return left(new AppError('DATABASE_ERROR', 'Erro ao atualizar reputação', 500));
    }
  }

  async uploadImage(
    file: { buffer: Buffer; mimetype: string },
  ): RepositoryResponse<{ imageId: string; url: string }> {
    try {
      const imageId = uuidv4();
      const url = `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
      return right({ imageId, url });
    } catch {
      return left(new AppError('IMAGE_ERROR', 'Erro ao processar imagem', 500));
    }
  }
}
