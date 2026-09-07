import { Prisma } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import {
  AttachGroupPaymentInput,
  CreatePaymentGroupInput,
  PaymentGroupSnapshot,
} from '../../types/payment-group.types';

export abstract class PaymentGroupRepository {
  abstract create(
    data: CreatePaymentGroupInput,
    tx: Prisma.TransactionClient,
  ): Promise<{ id: string }>;

  abstract findById(groupId: string): RepositoryResponse<PaymentGroupSnapshot | null>;

  abstract findByIdempotencyKey(
    idempotencyKey: string,
  ): RepositoryResponse<PaymentGroupSnapshot | null>;

  abstract attachPayment(data: AttachGroupPaymentInput): RepositoryResponse<void>;

  abstract claimPaid(
    groupId: string,
    chargeId: string | null,
    tx: Prisma.TransactionClient,
  ): Promise<number>;

  abstract markTerminal(
    groupId: string,
    status: 'FAILED' | 'EXPIRED',
    tx: Prisma.TransactionClient,
  ): Promise<number>;

  abstract findExpiredGroupIds(now: Date): RepositoryResponse<string[]>;
}
