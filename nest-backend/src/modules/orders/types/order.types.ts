import { EscrowStatus, OrderStatus, Prisma } from "@prisma/client";
import { USER_SELECT_MINIMAL } from "@/shared/utils/prisma-selects";

export const ORDER_INCLUDE_FULL = {
  product: { include: { images: true } },
  buyer: { select: USER_SELECT_MINIMAL },
  seller: { select: USER_SELECT_MINIMAL },
} satisfies Prisma.OrderInclude;

export const ORDER_INCLUDE_PRODUCT = {
  product: { include: { images: true } },
} satisfies Prisma.OrderInclude;

export const ORDER_SELECT_CREATE = {
  id: true,
  buyerId: true,
  sellerId: true,
  productId: true,
  amount: true,
  platformFee: true,
  sellerAmount: true,
  status: true,
  escrowStatus: true,
  createdAt: true,
} satisfies Prisma.OrderSelect;

export type OrderFullPayload = Prisma.OrderGetPayload<{
  include: typeof ORDER_INCLUDE_FULL;
}>;
export type OrderProductPayload = Prisma.OrderGetPayload<{
  include: typeof ORDER_INCLUDE_PRODUCT;
}>;
export type CreateOrderPayload = Prisma.OrderGetPayload<{
  select: typeof ORDER_SELECT_CREATE;
}>;

export const SALES_ORDER_STATUSES = [
  OrderStatus.PENDING,
  OrderStatus.CONFIRMED,
  OrderStatus.SHIPPED,
  OrderStatus.DELIVERED,
  OrderStatus.DISPUTED,
  OrderStatus.COMPLETED,
  OrderStatus.CANCELLED,
] as const satisfies readonly OrderStatus[];

export type SalesOrderStatus = (typeof SALES_ORDER_STATUSES)[number];

export interface SalesOrderCursor {
  scope: "seller-sales";
  sellerId: string;
  status: SalesOrderStatus | null;
  createdAt: Date;
  id: string;
}

export interface CreateOrderTxData {
  buyerId: string;
  productId: string;
  platformFeePercent?: number;
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
  status: OrderStatus;
  orderQuantity: number;
  sellerId: string;
  sellerAmount: number;
  reason: string;
}

// Webhook-initiated refunds carry no user-supplied reason; only the
// user-driven cancel path records one.
export interface RefundOrderTxData extends Omit<CancelOrderTxData, 'reason'> {
  status: OrderStatus;
  escrowStatus: Extract<EscrowStatus, 'HELD' | 'RELEASED'>;
  transferId: string | null;
}

export interface ProductForOrder {
  id: string;
  sellerId: string;
  price: number;
}
