import { z } from 'zod';
import { Dispute, Order, User, Product, Prisma } from '@prisma/client';

export const openDisputeSchema = z.object({
  orderId: z.string().uuid(),
  reason: z.string().min(1),
});

export type OpenDisputeInput = z.infer<typeof openDisputeSchema> & {
  userId: string;
};

export interface OpenDisputeOutput {
  id: string;
  orderId: string;
  openedById: string;
  reason: string;
  status: string;
  createdAt: Date;
  expiresAt: Date;
}

export interface SubmitEvidenceInput {
  disputeId: string;
  userId: string;
  evidence: Prisma.InputJsonValue;
}

export interface SubmitEvidenceOutput {
  submitted: boolean;
}

export interface ResolveDisputeInput {
  disputeId: string;
  resolution: string;
  winner: 'BUYER' | 'SELLER';
}

export interface ResolveDisputeOutput {
  resolved: boolean;
}

export type GetDisputeOutput = Dispute & {
  order: Order & {
    buyer: Pick<User, 'id' | 'displayName' | 'avatarUrl'>;
    seller: Pick<User, 'id' | 'displayName' | 'avatarUrl'>;
    product: Product;
  };
  openedBy: Pick<User, 'id' | 'displayName'>;
};

export type GetUserDisputesOutput = (Dispute & {
  order: Order & {
    product: Product;
  };
})[];
