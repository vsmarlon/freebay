import { Prisma, User, WebMagicLink } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';

export abstract class MagicLinkRepository {
  abstract create(data: Prisma.WebMagicLinkCreateInput): RepositoryResponse<WebMagicLink>;
  abstract recordSendAccepted(id: string, sendAcceptedAt: Date, resendMessageId: string): RepositoryResponse<WebMagicLink>;
  abstract consume(tokenHash: string, now: Date, allowRegistration?: boolean): RepositoryResponse<User | null>;
  abstract deleteExpiredOrConsumed(before: Date, consumedBefore: Date): RepositoryResponse<number>;
}
