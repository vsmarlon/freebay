import { Transaction, Order, PaymentMethod } from '@prisma/client';

export type TransactionWithOrder = Transaction & {
  order: Order & {
    buyer: { id: string; displayName: string };
    seller: { id: string; displayName: string };
  };
};

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
