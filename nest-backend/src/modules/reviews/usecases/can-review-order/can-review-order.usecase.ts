import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { OrderStatus, ReviewType } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CanReviewOrderUsecaseInput, CanReviewOrderUsecaseOutput } from './can-review-order.dto';

@Injectable()
export class CanReviewOrderUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(
    input: CanReviewOrderUsecaseInput,
  ): Promise<Either<AppError, CanReviewOrderUsecaseOutput>> {
    const order = await this.prisma.order.findUnique({
      where: { id: input.orderId },
    });

    if (!order) {
      return left(new NotFoundError('Order'));
    }

    const isBuyer = order.buyerId === input.userId;
    const isSeller = order.sellerId === input.userId;

    if (!isBuyer && !isSeller) {
      return right({
        canReview: false,
        reason: 'User is not part of this order',
      });
    }

    if (order.status !== OrderStatus.COMPLETED) {
      return right({
        canReview: false,
        reason: 'Order must be completed before reviewing',
      });
    }

    const reviewType = isBuyer
      ? ReviewType.BUYER_REVIEWING_SELLER
      : ReviewType.SELLER_REVIEWING_BUYER;

    const existingReview = await this.prisma.review.findUnique({
      where: {
        reviewerId_orderId_type: {
          reviewerId: input.userId,
          orderId: input.orderId,
          type: reviewType,
        },
      },
    });

    if (existingReview) {
      return right({
        canReview: false,
        reason: 'You have already reviewed this order',
      });
    }

    return right({
      canReview: true,
      reviewType,
    });
  }
}
