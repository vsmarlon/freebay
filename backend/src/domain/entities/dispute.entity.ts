export interface DisputeEntity {
  id: string;
  orderId: string;
  openedById: string;
  status: 'OPEN' | 'AWAITING_SELLER' | 'AWAITING_BUYER' | 'RESOLVED' | 'CANCELLED';
  reason: string;
  buyerEvidence: unknown;
  sellerEvidence: unknown;
  resolution: string | null;
  resolvedAt: Date | null;
  createdAt: Date;
  expiresAt: Date;
}
