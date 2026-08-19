import { RepositoryResponse } from '@/shared/core/either';
import { ChatThreadType, ConversationPreference } from '@prisma/client';
import { UpsertPreferenceInput } from '../../types/chat.types';

export abstract class ConversationPreferenceRepository {
  abstract findByAnyId(userId: string, threadId: string): RepositoryResponse<ConversationPreference | null>;
  abstract findByUserAndThread(userId: string, threadId: string, type: ChatThreadType): RepositoryResponse<ConversationPreference | null>;
  abstract upsert(input: UpsertPreferenceInput): RepositoryResponse<ConversationPreference>;
  abstract findArchived(userId: string): RepositoryResponse<ConversationPreference[]>;
  abstract findDeleted(userId: string): RepositoryResponse<ConversationPreference[]>;
}
