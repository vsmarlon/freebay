import { Prisma, ReviewType } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import { ReviewWithReviewer, ReviewWithDetails } from '../../types/review.types';

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
