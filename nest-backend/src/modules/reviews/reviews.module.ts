import { Module } from '@nestjs/common';
import { ReviewsController } from './reviews.controller';
import { CreateReviewUseCase } from './usecases/create-review.usecase';
import { GetUserReviewsUseCase } from './usecases/get-user-reviews.usecase';
import { CanReviewOrderUseCase } from './usecases/can-review-order.usecase';
import { PrismaReviewRepository } from './repositories/review.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [ReviewsController],
  providers: [
    CreateReviewUseCase,
    GetUserReviewsUseCase,
    CanReviewOrderUseCase,
    PrismaReviewRepository,
    PrismaService,
  ],
  exports: [PrismaReviewRepository],
})
export class ReviewsModule {}
