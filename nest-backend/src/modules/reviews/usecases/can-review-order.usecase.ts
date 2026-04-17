import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { OrderStatus, ReviewType } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

export interface CanReviewOrderInput {
  orderId: string;
  userId: string;
}

export interface CanReviewOrderOutput {
  canReview: boolean;
  reviewType?: ReviewType;
  reason?: string;
}

@Injectable()
export class CanReviewOrderUseCase {
  constructor(private readonly prisma: PrismaService) {}

  async execute(
    input: CanReviewOrderInput,
  ): Promise<Either<AppError, CanReviewOrderOutput>> {
    // 1. Check if order exists
    const order = await this.prisma.order.findUnique({
      where: { id: input.orderId },
    });

    if (!order) {
      return left(new NotFoundError('Order'));
    }

    // 2. Check if user is part of the order (buyer or seller)
    const isBuyer = order.buyerId === input.userId;
    const isSeller = order.sellerId === input.userId;

    if (!isBuyer && !isSeller) {
      return right({
        canReview: false,
        reason: 'User is not part of this order',
      });
    }

    // 3. Check if order is completed
    if (order.status !== OrderStatus.COMPLETED) {
      return right({
        canReview: false,
        reason: 'Order must be completed before reviewing',
      });
    }

    // 4. Determine review type
    const reviewType = isBuyer
      ? ReviewType.BUYER_REVIEWING_SELLER
      : ReviewType.SELLER_REVIEWING_BUYER;

    // 5. Check if user already reviewed
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

    // 6. User can review
    return right({
      canReview: true,
      reviewType,
    });
  }
}
