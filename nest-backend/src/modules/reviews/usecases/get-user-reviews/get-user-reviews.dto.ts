import { ReviewType } from '@prisma/client';

export interface GetUserReviewsUsecaseInput {
  userId: string;
  offset?: number;
  limit?: number;
  type?: ReviewType;
}

export interface GetUserReviewsUsecaseOutput {
  reviews: {
    id: string;
    reviewerId: string;
    reviewedId: string;
    orderId: string;
    type: ReviewType;
    score: number;
    comment: string | null;
    createdAt: string;
    images: { id: string; url: string; order: number }[];
    reviewer: {
      id: string;
      displayName: string;
      avatarUrl: string | null;
      isVerified: boolean;
    };
  }[];
  total: number;
  offset: number;
  limit: number;
}
