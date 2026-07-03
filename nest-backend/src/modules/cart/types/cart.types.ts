import { Prisma } from '@prisma/client';

export const CART_ITEM_INCLUDE = {
  product: {
    include: {
      seller: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
      images: { orderBy: { order: 'asc' as const }, take: 1 },
    },
  },
} satisfies Prisma.CartItemInclude;

export type CartItemPayload = Prisma.CartItemGetPayload<{ include: typeof CART_ITEM_INCLUDE }>;

export interface ProductBrief {
  id: string;
  sellerId: string;
  status: string;
  price: number;
}
