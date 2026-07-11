import { RepositoryResponse } from '@/shared/core/either';
import { PhoneVerificationCode, Prisma } from '@prisma/client';

export abstract class PhoneVerificationRepository {
  abstract create(data: Prisma.PhoneVerificationCodeCreateInput): RepositoryResponse<PhoneVerificationCode>;
  abstract findLatestByUserId(userId: string): RepositoryResponse<PhoneVerificationCode | null>;
  abstract incrementAttempts(id: string): RepositoryResponse<PhoneVerificationCode>;
  abstract markSent(
    id: string,
    provider?: string | null,
    providerMessageId?: string | null,
  ): RepositoryResponse<PhoneVerificationCode>;
  abstract markUsed(id: string): RepositoryResponse<PhoneVerificationCode>;
  abstract deleteManyForUser(userId: string): RepositoryResponse<void>;
}
