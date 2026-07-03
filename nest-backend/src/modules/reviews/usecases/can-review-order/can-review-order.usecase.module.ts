import { Module } from '@nestjs/common';
import { CanReviewOrderUseCase } from './can-review-order.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  providers: [CanReviewOrderUseCase, PrismaService],
  exports: [CanReviewOrderUseCase],
})
export class CanReviewOrderUseCaseModule {}
