import { Module } from '@nestjs/common';
import { ReviewsController } from './reviews.controller';
import { ReviewsService } from './reviews.service';
import { CreateReviewUseCaseModule } from '../usecases/create-review/create-review.usecase.module';
import { GetUserReviewsUseCaseModule } from '../usecases/get-user-reviews/get-user-reviews.usecase.module';
import { CanReviewOrderUseCaseModule } from '../usecases/can-review-order/can-review-order.usecase.module';
import { ReviewRepository } from '../domain/repositories/review.repository';
import { PrismaReviewRepository } from '../data/repositories/review-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  imports: [
    CreateReviewUseCaseModule,
    GetUserReviewsUseCaseModule,
    CanReviewOrderUseCaseModule,
  ],
  controllers: [ReviewsController],
  providers: [
    ReviewsService,
    { provide: ReviewRepository, useClass: PrismaReviewRepository },
    PrismaService,
  ],
})
export class ReviewsModule {}
