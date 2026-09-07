import { Either } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import Stripe from 'stripe';

export interface PaymentLineItem {
  name: string;
  amount: number;
  quantity: number;
}

export interface PaymentSessionParams {
  orderId?: string;
  paymentGroupId?: string;
  amount: number;
  currency: string;
  customerEmail?: string;
  customerName?: string;
  customerTaxId?: string;
  idempotencyKey?: string;
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
}

export interface PaymentIntentResult {
  paymentIntentId: string;
  clientSecret: string;
}

export abstract class PaymentProvider {
  abstract createPaymentSession(
    params: PaymentSessionParams,
  ): Promise<Either<AppError, PaymentSessionResult>>;

  abstract createPaymentIntent(
    params: PaymentIntentParams,
  ): Promise<Either<AppError, PaymentIntentResult>>;

  abstract verifyWebhook(payload: string, signature: string): boolean;

  abstract constructWebhookEvent(
    payload: string,
    signature: string,
  ): Stripe.Event | null;
}
