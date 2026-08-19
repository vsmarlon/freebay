import { Prisma } from '@prisma/client';

export const reviewWithReviewer = Prisma.validator<Prisma.ReviewDefaultArgs>()({
  include: {
    reviewer: {
      select: { id: true, displayName: true, avatarUrl: true, isVerified: true },
    },
    images: { orderBy: { order: 'asc' as const } },
  },
});

export type ReviewWithReviewer = Prisma.ReviewGetPayload<typeof reviewWithReviewer>;

export const reviewWithDetails = Prisma.validator<Prisma.ReviewDefaultArgs>()({
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
