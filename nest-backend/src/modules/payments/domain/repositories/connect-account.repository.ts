import { ConnectAccount, Prisma } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import { ConnectAccountSnapshot } from '../../types/connect.types';

export abstract class ConnectAccountRepository {
  abstract findByUserId(userId: string): RepositoryResponse<ConnectAccount | null>;
  abstract findByStripeAccountId(stripeAccountId: string): RepositoryResponse<ConnectAccount | null>;
  abstract findUserContact(
    userId: string,
  ): RepositoryResponse<{ email: string; displayName: string } | null>;
  abstract upsertFromSnapshot(
    userId: string,
    snapshot: ConnectAccountSnapshot,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<ConnectAccount>;
}
