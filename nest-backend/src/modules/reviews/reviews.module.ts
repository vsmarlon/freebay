import { Module } from '@nestjs/common';
import { ReviewsController } from './reviews.controller';
import { ReviewsService } from './reviews.service';
import { CreateReviewUseCase } from './usecases/create-review/create-review.usecase';
import { GetUserReviewsUseCase } from './usecases/get-user-reviews/get-user-reviews.usecase';
import { CanReviewOrderUseCase } from './usecases/can-review-order/can-review-order.usecase';
import { ReviewDatabaseRepository } from './data/repositories/review-database.repository';

@Module({
  controllers: [ReviewsController],
  providers: [
    ReviewsService,
    ReviewDatabaseRepository,
    CreateReviewUseCase,
    GetUserReviewsUseCase,
    CanReviewOrderUseCase,
  ],
})
export class ReviewsModule {}
