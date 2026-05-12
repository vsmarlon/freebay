import { z } from 'zod';
import { ReviewType } from '@prisma/client';

export const createReviewSchema = z.object({
  reviewerId: z.string().uuid(),
  orderId: z.string().uuid(),
  reviewedId: z.string().uuid(),
  type: z.nativeEnum(ReviewType),
  score: z.number().int().min(1).max(5),
  comment: z.string().max(500).optional(),
});

export type CreateReviewDto = z.infer<typeof createReviewSchema>;

export const getUserReviewsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(10),
  type: z.nativeEnum(ReviewType).optional(),
});

export type GetUserReviewsQueryDto = z.infer<typeof getUserReviewsQuerySchema>;

export interface GetUserReviewsInput {
  userId: string;
  page?: number;
  limit?: number;
  type?: ReviewType;
}

export interface ReviewApiResponse {
  id: string;
  reviewerId: string;
  reviewedId: string;
  orderId: string;
  type: ReviewType;
  score: number;
  comment: string | null;
  createdAt: string;
  reviewer: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
}

export interface GetUserReviewsOutput {
  reviews: ReviewApiResponse[];
  total: number;
  page: number;
  limit: number;
}

export interface CreateReviewOutput {
  id: string;
  reviewerId: string;
  reviewedId: string;
  orderId: string;
  type: ReviewType;
  score: number;
  comment: string | null;
  createdAt: Date;
}
