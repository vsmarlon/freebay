import { Prisma } from '@prisma/client';

export type FavoriteWithProduct = Prisma.FavoriteGetPayload<{
  include: {
    product: {
      include: {
        seller: { select: { id: true; displayName: true; avatarUrl: true; isVerified: true; reputationScore: true; totalReviews: true } };
        images: { orderBy: { order: 'asc' }; take: 1 };
      };
    };
  };
}>;
