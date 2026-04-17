import { Review, User } from '@prisma/client';

export type ReviewWithReviewer = Review & {
  reviewer: Pick<User, 'id' | 'displayName' | 'avatarUrl' | 'isVerified'>;
};

export type ReviewWithReviewerAndReviewed = Review & {
  reviewer: Pick<User, 'id' | 'displayName' | 'avatarUrl' | 'isVerified'>;
  reviewed: Pick<User, 'id' | 'displayName' | 'avatarUrl' | 'isVerified'>;
};

export class ReviewMapper {
  static toApiResponse(review: ReviewWithReviewer) {
    return {
      id: review.id,
      reviewerId: review.reviewerId,
      reviewedId: review.reviewedId,
      orderId: review.orderId,
      type: review.type,
      score: review.score,
      comment: review.comment,
      createdAt: review.createdAt.toISOString(),
      reviewer: {
        id: review.reviewer.id,
        displayName: review.reviewer.displayName,
        avatarUrl: review.reviewer.avatarUrl,
        isVerified: review.reviewer.isVerified,
      },
    };
  }

  static toApiResponseWithReviewed(review: ReviewWithReviewerAndReviewed) {
    return {
      ...this.toApiResponse(review),
      reviewed: {
        id: review.reviewed.id,
        displayName: review.reviewed.displayName,
        avatarUrl: review.reviewed.avatarUrl,
        isVerified: review.reviewed.isVerified,
      },
    };
  }
}
