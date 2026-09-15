import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaReviewRepository } from '@/modules/reviews/data/repositories/review-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { GetUserReviewsUsecaseInput, GetUserReviewsUsecaseOutput } from './get-user-reviews.dto';

@Injectable()
export class GetUserReviewsUseCase {
  constructor(
    private readonly reviewRepository: PrismaReviewRepository,
    private readonly prisma: PrismaService,
  ) {}

  async execute(
    input: GetUserReviewsUsecaseInput,
  ): Promise<Either<AppError, GetUserReviewsUsecaseOutput>> {
    const { userId, offset = 0, limit = 10, type } = input;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      return left(new NotFoundError('Usuário'));
    }

    const result = await this.reviewRepository.findByReviewedId(userId, {
      offset,
      limit,
      type,
    });

    if (result.isLeft()) {
      return left(result.value);
    }

    return right({
      reviews: result.value.reviews.map((review) => ({
        id: review.id,
        reviewerId: review.reviewerId,
        reviewedId: review.reviewedId,
        orderId: review.orderId,
        type: review.type,
        score: review.score,
        comment: review.comment,
        createdAt: review.createdAt.toISOString(),
        images: review.images.map((img) => ({
          id: img.id,
          url: img.url,
          order: img.order,
        })),
        reviewer: {
          id: review.reviewer.id,
          displayName: review.reviewer.displayName,
          avatarUrl: review.reviewer.avatarUrl,
          isVerified: review.reviewer.isVerified,
        },
      })),
      total: result.value.total,
      offset: result.value.offset,
      limit: result.value.limit,
    });
  }
}
