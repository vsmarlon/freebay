import { Dispute, Order } from '@prisma/client';

export type DisputeWithOrder = Dispute & { order: Order };

export interface CreateDisputeInput {
  orderId: string;
  openedById: string;
  reason: string;
  expiresAt: Date;
}
