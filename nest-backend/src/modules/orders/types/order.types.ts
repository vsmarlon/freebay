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
