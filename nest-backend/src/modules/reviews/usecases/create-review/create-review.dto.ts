import { ReviewType } from '@prisma/client';

export interface CreateReviewUsecaseInput {
  reviewerId: string;
  orderId: string;
  reviewedId: string;
  type: ReviewType;
  score: number;
  comment?: string;
  imageUrls?: string[];
}

export interface CreateReviewUsecaseOutput {
  id: string;
  reviewerId: string;
  reviewedId: string;
  orderId: string;
  type: ReviewType;
  score: number;
  comment: string | null;
  createdAt: Date;
  images: { id: string; url: string; order: number }[];
  reviewer: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
}
