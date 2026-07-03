import { ReviewType } from '@prisma/client';

export interface CanReviewOrderUsecaseInput {
  orderId: string;
  userId: string;
}

export interface CanReviewOrderUsecaseOutput {
  canReview: boolean;
  reviewType?: ReviewType;
  reason?: string;
}
