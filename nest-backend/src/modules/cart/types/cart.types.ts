import { Prisma, ProductStatus } from '@prisma/client';
import { USER_SELECT_BASIC } from '@/shared/utils/prisma-selects';

export const CART_ITEM_INCLUDE = {
  product: {
    include: {
      seller: { select: USER_SELECT_BASIC },
      media: { orderBy: { order: 'asc' as const }, take: 1 },
    },
  },
} satisfies Prisma.CartItemInclude;

export type CartItemPayload = Prisma.CartItemGetPayload<{ include: typeof CART_ITEM_INCLUDE }>;

export interface ProductBrief {
  id: string;
  sellerId: string;
  status: ProductStatus;
  price: number;
  quantity: number;
  soldCount: number;
}

export interface ReserveOrderInput {
  userId: string;
  sellerId: string;
  productId: string;
  quantity: number;
  amount: number;
  platformFee: number;
  sellerAmount: number;
}

export const PRODUCT_UNAVAILABLE = 'PRODUCT_UNAVAILABLE';
