import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaReviewRepository } from '../repositories/review.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ReviewMapper } from '../mappers/review.mapper';
import { GetUserReviewsInput, GetUserReviewsOutput } from '../dtos/review.dto';

@Injectable()
export class GetUserReviewsUseCase {
  constructor(
    private reviewRepository: PrismaReviewRepository,
    private prisma: PrismaService,
  ) {}

  async execute(input: GetUserReviewsInput): Promise<Either<AppError, GetUserReviewsOutput>> {
    const { userId, page = 1, limit = 10, type } = input;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      return left(new NotFoundError('Usuário'));
    }

    const result = await this.reviewRepository.findByReviewedId(userId, {
      page,
      limit,
      type,
    });

    return right({
      reviews: result.reviews.map((review) => ReviewMapper.toApiResponse(review)),
      total: result.total,
      page: result.page,
      limit: result.limit,
    });
  }
}
