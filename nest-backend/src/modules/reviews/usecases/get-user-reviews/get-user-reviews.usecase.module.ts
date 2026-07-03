import { Module } from '@nestjs/common';
import { GetUserReviewsUseCase } from './get-user-reviews.usecase';
import { ReviewRepository } from '@/modules/reviews/domain/repositories/review.repository';
import { PrismaReviewRepository } from '@/modules/reviews/data/repositories/review-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  providers: [
    GetUserReviewsUseCase,
    { provide: ReviewRepository, useClass: PrismaReviewRepository },
    PrismaService,
  ],
  exports: [GetUserReviewsUseCase],
})
export class GetUserReviewsUseCaseModule {}
