import { ApiProperty } from '@nestjs/swagger';

export interface CreatePaymentSessionInput {
  readonly orderId: string;
  readonly userId: string;
  readonly customerName?: string;
  readonly customerTaxId?: string;
  readonly customerEmail?: string;
  readonly idempotencyKey?: string;
}

export interface ProcessWebhookInput {
  readonly event: string;
  readonly data: WebhookDataPayload;
}

export interface WebhookDataPayload {
  readonly orderId?: string;
  readonly providerObjectId?: string;
  readonly amountTotal?: number;
  readonly currency?: string;
  readonly paymentStatus?: string;
}

export interface ProcessWebhookOutput {
  readonly processed: boolean;
}

export interface CreateWithdrawalInput {
  readonly withdrawalId: string;
}

export interface CreateWithdrawalOutput {
  readonly transferred: boolean;
}

export class CreatePaymentSessionOutput {
  @ApiProperty({ example: 'cs_test_abc123' })
  readonly stripeSessionId: string;

  @ApiProperty({ example: 'https://checkout.stripe.com/pay/cs_test_abc123' })
  readonly checkoutUrl: string;

  @ApiProperty({ example: '2026-06-17T13:00:00.000Z' })
  readonly expiresAt: Date;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly orderId: string;
}

export interface CreatePaymentIntentInput {
  readonly orderId: string;
  readonly userId: string;
  readonly idempotencyKey?: string;
}

export class CreatePaymentIntentOutput {
  @ApiProperty({ example: 'pi_3..._secret_...' })
  readonly paymentIntentClientSecret: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly orderId: string;
}

