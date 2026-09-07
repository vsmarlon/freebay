import { PaymentGroupStatus, TransactionStatus } from '@prisma/client';

export interface PaymentGroupOrderInput {
  orderId: string;
  amount: number;
  platformFee: number;
  sellerAmount: number;
}

export interface CreatePaymentGroupInput {
  buyerId: string;
  amount: number;
  currency: string;
  idempotencyKey: string;
  expiresAt: Date;
  orders: PaymentGroupOrderInput[];
}

export interface AttachGroupPaymentInput {
  groupId: string;
  stripePaymentIntentId?: string | null;
  stripeSessionId?: string | null;
  clientSecret?: string | null;
  checkoutUrl?: string | null;
  expiresAt?: Date | null;
}

export interface PaymentGroupOrderRow {
  orderId: string;
  transactionId: string;
  transactionStatus: TransactionStatus;
  amount: number;
  sellerAmount: number;
  buyerId: string;
  sellerId: string;
  productId: string;
  productTitle: string;
  quantity: number;
}

export interface PaymentGroupSnapshot {
  id: string;
  buyerId: string;
  amount: number;
  currency: string;
  status: PaymentGroupStatus;
  stripePaymentIntentId: string | null;
  stripeSessionId: string | null;
  clientSecret: string | null;
  checkoutUrl: string | null;
  expiresAt: Date | null;
  orders: PaymentGroupOrderRow[];
}
