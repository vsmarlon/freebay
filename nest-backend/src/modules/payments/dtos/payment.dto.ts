import { ApiProperty } from '@nestjs/swagger';

export interface CreatePixPaymentInput {
  orderId: string;
  userId: string;
  customerName?: string;
  customerTaxId?: string;
  customerEmail?: string;
  idempotencyKey?: string;
}

export interface ProcessWebhookInput {
  event: string;
  data: WebhookDataPayload;
}

export interface WebhookDataPayload {
  correlationID?: string;
  [key: string]: string | number | boolean | null | object | undefined;
}

export interface ProcessWebhookOutput {
  processed: boolean;
}

export interface CreateWithdrawalInput {
  withdrawalId: string;
}

export interface CreateWithdrawalOutput {
  transferred: boolean;
}

export class CreatePixPaymentOutput {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly orderId: string;

  @ApiProperty({ example: '00020126580014BR.GOV.BCB.PIX...' })
  readonly pixQrCode: string;

  @ApiProperty({ example: 'data:image/png;base64,...' })
  readonly pixImage: string;

  @ApiProperty({ example: '2026-06-17T13:00:00.000Z' })
  readonly expiresAt: Date;
}
