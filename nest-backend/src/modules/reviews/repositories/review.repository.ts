import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma, ReviewType } from '@prisma/client';
import { USER_SELECT_BASIC } from '@/shared/utils/prisma-selects';

@Injectable()
export class PrismaReviewRepository {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    return this.prisma.review.findUnique({
      where: { id },
      include: {
        reviewer: { select: USER_SELECT_BASIC },
        reviewed: { select: USER_SELECT_BASIC },
      },
    });
  }

  async findByReviewedId(
    reviewedId: string,
    options?: { offset?: number; limit?: number; type?: ReviewType },
  ) {
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
        include: {
          reviewer: { select: USER_SELECT_BASIC },
        },
      }),
      this.prisma.review.count({ where }),
    ]);

    return { reviews, total, offset, limit };
  }

  async findByOrderAndType(orderId: string, type: ReviewType) {
    return this.prisma.review.findFirst({
      where: { orderId, type },
    });
  }

  async findExistingReview(reviewerId: string, orderId: string, type: ReviewType) {
    return this.prisma.review.findUnique({
      where: {
        reviewerId_orderId_type: {
          reviewerId,
          orderId,
          type,
        },
      },
    });
  }

  async create(data: Prisma.ReviewCreateInput) {
    return this.prisma.review.create({
      data,
      include: {
        reviewer: { select: USER_SELECT_BASIC },
      },
    });
  }

  async calculateAverageScore(userId: string): Promise<number> {
    const result = await this.prisma.review.aggregate({
      where: { reviewedId: userId },
      _avg: { score: true },
    });

    return result._avg.score ?? 0;
  }

  async countReviews(userId: string): Promise<number> {
    return this.prisma.review.count({
      where: { reviewedId: userId },
    });
  }

  async updateUserReputation(userId: string) {
    const [averageScore, totalReviews] = await Promise.all([
      this.calculateAverageScore(userId),
      this.countReviews(userId),
    ]);

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        reputationScore: averageScore,
        totalReviews,
      },
    });

    return { reputationScore: averageScore, totalReviews };
  }
}
