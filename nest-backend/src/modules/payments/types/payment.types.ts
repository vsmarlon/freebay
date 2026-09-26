import { Prisma, PaymentMethod } from '@prisma/client';

export const TRANSACTION_WITH_ORDER_INCLUDE = {
  order: { include: {
    buyer: { select: { id: true, displayName: true } },
    seller: { select: { id: true, displayName: true } },
  } },
} satisfies Prisma.TransactionInclude;

export type TransactionWithOrder = Prisma.TransactionGetPayload<{
  include: typeof TRANSACTION_WITH_ORDER_INCLUDE;
}>;

export interface ExpiredPendingTransaction {
  readonly id: string;
  readonly orderId: string;
  readonly productId: string;
  readonly quantity: number;
}

export interface UpsertTransactionData {
  readonly orderId: string;
  readonly externalId: string;
  readonly amount: number;
  readonly platformFee: number;
  readonly sellerAmount: number;
  readonly paymentMethod: PaymentMethod;
  readonly idempotencyKey: string;
  readonly checkoutUrl?: string;
  readonly checkoutExpiresAt?: Date;
}
