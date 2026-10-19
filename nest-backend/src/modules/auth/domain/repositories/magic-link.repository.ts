import { Prisma, User, WebMagicLink } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';

export type ConsumedMagicLink = { user: User; sessionStartedAtMs: number };

export abstract class MagicLinkRepository {
  abstract create(data: Prisma.WebMagicLinkCreateInput): RepositoryResponse<WebMagicLink>;
  abstract recordSendAccepted(id: string, sendAcceptedAt: Date, resendMessageId: string): RepositoryResponse<WebMagicLink>;
  abstract consume(tokenHash: string, now: Date, allowRegistration?: boolean): RepositoryResponse<ConsumedMagicLink | null>;
  abstract consumeStepUpProof(tokenHash: string, userId: string, sessionStartedAtMs: number, now: Date): RepositoryResponse<boolean>;
  abstract deleteExpiredOrConsumed(before: Date, consumedBefore: Date): RepositoryResponse<number>;
}
