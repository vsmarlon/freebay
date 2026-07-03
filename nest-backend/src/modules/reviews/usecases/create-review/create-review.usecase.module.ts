import { Module } from '@nestjs/common';
import { CreateReviewUseCase } from './create-review.usecase';
import { ReviewRepository } from '@/modules/reviews/domain/repositories/review.repository';
import { PrismaReviewRepository } from '@/modules/reviews/data/repositories/review-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  providers: [
    CreateReviewUseCase,
    { provide: ReviewRepository, useClass: PrismaReviewRepository },
    PrismaService,
  ],
  exports: [CreateReviewUseCase],
})
export class CreateReviewUseCaseModule {}
