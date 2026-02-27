export interface TransactionEntity {
  id: string;
  orderId: string;
  externalId: string | null;
  amount: number;
  platformFee: number;
  sellerAmount: number;
  paymentMethod: 'PIX' | 'CREDIT_CARD';
  provider: 'PAGARME' | 'WOOVI';
  status: 'PENDING' | 'PROCESSING' | 'PAID' | 'HELD' | 'RELEASED' | 'REFUNDED' | 'FAILED';
  idempotencyKey: string;
  pixQrCode: string | null;
  pixExpiresAt: Date | null;
  paidAt: Date | null;
  releasedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}
