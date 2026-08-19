import { Prisma } from '@prisma/client';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';

export const ORDER_INCLUDE_FULL = {
  product: { include: { images: true } },
  buyer: { select: USER_SELECT_MINIMAL },
  seller: { select: USER_SELECT_MINIMAL },
} satisfies Prisma.OrderInclude;

export const ORDER_INCLUDE_PRODUCT = {
  product: { include: { images: true } },
} satisfies Prisma.OrderInclude;

export type OrderFullPayload = Prisma.OrderGetPayload<{ include: typeof ORDER_INCLUDE_FULL }>;
export type OrderProductPayload = Prisma.OrderGetPayload<{ include: typeof ORDER_INCLUDE_PRODUCT }>;

export interface CreateOrderTxData {
  buyerId: string;
  sellerId: string;
  productId: string;
  amount: number;
  platformFee: number;
  sellerAmount: number;
}

export interface ConfirmDeliveryData {
  orderId: string;
  sellerId: string;
  sellerAmount: number;
}

export interface CancelOrderTxData {
  orderId: string;
  productId: string;
  buyerId: string;
  amount: number;
  status: string;
  quantity: number;
  sellerId: string;
  sellerAmount: number;
}

export interface ProductForOrder {
  id: string;
  sellerId: string;
  price: number;
}
