import { RepositoryResponse } from '@/shared/core/either';
import { Dispute, Prisma } from '@prisma/client';
import { GetDisputeOutput, GetUserDisputesOutput } from '../../dtos/dispute.dto';
import { DisputeWithOrder, CreateDisputeInput } from '../../types/dispute.types';

export abstract class DisputeRepository {
  abstract create(data: CreateDisputeInput): RepositoryResponse<Dispute>;
  abstract findById(id: string): RepositoryResponse<DisputeWithOrder | null>;
  abstract findByIdWithDetails(id: string): RepositoryResponse<GetDisputeOutput | null>;
  abstract findByUserId(userId: string): RepositoryResponse<GetUserDisputesOutput>;
  abstract update(id: string, data: Prisma.DisputeUpdateInput): RepositoryResponse<Dispute>;
}
