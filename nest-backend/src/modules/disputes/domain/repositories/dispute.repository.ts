import { RepositoryResponse } from '@/shared/core/either';
import { Dispute, Order, Prisma } from '@prisma/client';
import { GetDisputeOutput, GetUserDisputesOutput } from '../../dtos/dispute.dto';

export type DisputeWithOrder = Dispute & { order: Order };

export interface CreateDisputeInput {
  orderId: string;
  openedById: string;
  reason: string;
  expiresAt: Date;
}

export abstract class DisputeRepository {
  abstract create(data: CreateDisputeInput): RepositoryResponse<Dispute>;
  abstract findById(id: string): RepositoryResponse<DisputeWithOrder | null>;
  abstract findByIdWithDetails(id: string): RepositoryResponse<GetDisputeOutput | null>;
  abstract findByUserId(userId: string): RepositoryResponse<GetUserDisputesOutput>;
  abstract update(id: string, data: Prisma.DisputeUpdateInput): RepositoryResponse<Dispute>;
}
