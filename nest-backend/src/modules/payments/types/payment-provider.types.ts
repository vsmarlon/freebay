export interface PaymentLineItem {
  name: string;
  amount: number;
  quantity: number;
}

export interface PaymentSessionParams {
  orderId?: string;
  paymentGroupId?: string;
  buyerId?: string;
  amount: number;
  currency: string;
  customerEmail?: string;
  customerName?: string;
  customerTaxId?: string;
  idempotencyKey?: string;
  expiresAt?: Date;
  transferGroup?: string;
  lineItems?: PaymentLineItem[];
  successUrl: string;
  cancelUrl: string;
}

export interface PaymentSessionResult {
  stripeSessionId: string;
  checkoutUrl: string;
  expiresAt: Date;
}

export interface PaymentIntentParams {
  orderId?: string;
  paymentGroupId?: string;
  amount: number;
  currency: string;
  receiptEmail?: string;
  idempotencyKey?: string;
  transferGroup?: string;
}

export interface PaymentSessionSnapshot {
  stripeSessionId: string;
  checkoutUrl: string | null;
  status: string | null;
  mode: string;
  paymentStatus: string;
  amountTotal: number | null;
  currency: string | null;
  orderId: string | null;
  paymentGroupId: string | null;
  buyerId: string | null;
  idempotencyKey: string | null;
  expiresAt: Date | null;
}

export interface PaymentIntentResult {
  paymentIntentId: string;
  clientSecret: string;
}

export enum RefundStatus {
  PENDING = 'pending',
  REQUIRES_ACTION = 'requires_action',
  SUCCEEDED = 'succeeded',
  FAILED = 'failed',
  CANCELED = 'canceled',
  UNKNOWN = 'unknown',
}

export interface RefundSnapshot {
  id: string;
  chargeId: string | null;
  amount: number;
  status: RefundStatus;
  orderId: string | null;
  operationId: string | null;
}

export interface ChargeRefundSnapshot {
  id: string;
  amount: number;
  amountRefunded: number;
  refunds: RefundSnapshot[];
}
