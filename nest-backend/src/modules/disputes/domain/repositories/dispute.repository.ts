import { Dispute, Order, Prisma } from '@prisma/client';
import { GetDisputeOutput, GetUserDisputesOutput } from '../../dtos/dispute.dto';

export type DisputeWithOrder = Dispute & { order: Order };

export abstract class DisputeRepository {
  abstract create(data: {
    orderId: string;
    openedById: string;
    reason: string;
    expiresAt: Date;
  }): Promise<Dispute>;

  abstract findById(id: string): Promise<DisputeWithOrder | null>;

  abstract findByIdWithDetails(id: string): Promise<GetDisputeOutput | null>;

  abstract findByUserId(userId: string): Promise<GetUserDisputesOutput>;

  abstract update(id: string, data: Prisma.DisputeUpdateInput): Promise<Dispute>;

  abstract findOrderWithDispute(orderId: string): Promise<(Order & { dispute: Dispute | null }) | null>;

  abstract updateOrderStatus(orderId: string, status: string): Promise<void>;

  abstract transaction<T>(fn: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T>;
}
