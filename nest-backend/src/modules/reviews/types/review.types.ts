import { Prisma } from '@prisma/client';
import { USER_SELECT_BASIC } from '@/shared/utils/prisma-selects';

export const reviewWithReviewer = Prisma.validator<Prisma.ReviewDefaultArgs>()({
  include: {
    reviewer: {
      select: USER_SELECT_BASIC,
    },
    images: { orderBy: { order: 'asc' as const } },
  },
});

export type ReviewWithReviewer = Prisma.ReviewGetPayload<typeof reviewWithReviewer>;

export const reviewWithDetails = Prisma.validator<Prisma.ReviewDefaultArgs>()({
  include: {
    reviewer: {
      select: USER_SELECT_BASIC,
    },
    reviewed: {
      select: USER_SELECT_BASIC,
    },
    images: { orderBy: { order: 'asc' as const } },
  },
});

export type ReviewWithDetails = Prisma.ReviewGetPayload<typeof reviewWithDetails>;

export const REVIEW_INCLUDE = reviewWithReviewer.include;
export const REVIEW_DETAILED_INCLUDE = reviewWithDetails.include;
