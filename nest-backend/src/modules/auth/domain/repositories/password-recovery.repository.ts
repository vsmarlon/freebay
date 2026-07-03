import { RepositoryResponse } from '@/shared/core/either';
import { PasswordRecoveryCode, Prisma } from '@prisma/client';

export abstract class PasswordRecoveryRepository {
  abstract create(data: Prisma.PasswordRecoveryCodeCreateInput): RepositoryResponse<PasswordRecoveryCode>;
  abstract findLatestActiveByEmail(email: string): RepositoryResponse<PasswordRecoveryCode | null>;
  abstract findLatestByEmail(email: string): RepositoryResponse<PasswordRecoveryCode | null>;
  abstract incrementAttempts(id: string): RepositoryResponse<PasswordRecoveryCode>;
  abstract markSent(id: string, resendMessageId?: string | null): RepositoryResponse<PasswordRecoveryCode>;
  abstract markUsed(id: string): RepositoryResponse<PasswordRecoveryCode>;
  abstract deleteManyForUser(userId: string): RepositoryResponse<void>;
}
