import { Prisma } from '@prisma/client';
import { SELLER_SELECT_FULL } from '@/shared/utils/prisma-selects';

export type FavoriteWithProduct = Prisma.FavoriteGetPayload<{
  include: {
    product: {
      include: {
        seller: { select: typeof SELLER_SELECT_FULL };
        media: { orderBy: { order: 'asc' }; take: 1 };
      };
    };
  };
}>;
