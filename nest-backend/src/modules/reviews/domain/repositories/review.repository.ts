import { Prisma, ReviewType } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';

const reviewWithReviewer = Prisma.validator<Prisma.ReviewDefaultArgs>()({
  include: {
    reviewer: {
      select: { id: true, displayName: true, avatarUrl: true, isVerified: true },
    },
    images: { orderBy: { order: 'asc' as const } },
  },
});

export type ReviewWithReviewer = Prisma.ReviewGetPayload<typeof reviewWithReviewer>;

const reviewWithDetails = Prisma.validator<Prisma.ReviewDefaultArgs>()({
  include: {
    reviewer: {
      select: { id: true, displayName: true, avatarUrl: true, isVerified: true },
    },
    reviewed: {
      select: { id: true, displayName: true, avatarUrl: true, isVerified: true },
    },
    images: { orderBy: { order: 'asc' as const } },
  },
});

export type ReviewWithDetails = Prisma.ReviewGetPayload<typeof reviewWithDetails>;

export const REVIEW_INCLUDE = reviewWithReviewer.include;
export const REVIEW_DETAILED_INCLUDE = reviewWithDetails.include;

export abstract class ReviewRepository {
  abstract findById(id: string): RepositoryResponse<ReviewWithDetails | null>;

  abstract findByReviewedId(
    reviewedId: string,
    options?: { offset?: number; limit?: number; type?: ReviewType },
  ): RepositoryResponse<{
    reviews: ReviewWithReviewer[];
    total: number;
    offset: number;
    limit: number;
  }>;

  abstract findByOrderAndType(
    orderId: string,
    type: ReviewType,
  ): RepositoryResponse<ReviewWithReviewer | null>;

  abstract findExistingReview(
    reviewerId: string,
    orderId: string,
    type: ReviewType,
  ): RepositoryResponse<ReviewWithReviewer | null>;

  abstract create(data: Prisma.ReviewCreateInput): RepositoryResponse<ReviewWithReviewer>;

  abstract updateUserReputation(
    userId: string,
  ): RepositoryResponse<{ reputationScore: number; totalReviews: number }>;

  abstract uploadImage(
    file: { buffer: Buffer; mimetype: string },
  ): RepositoryResponse<{ imageId: string; url: string }>;
}
