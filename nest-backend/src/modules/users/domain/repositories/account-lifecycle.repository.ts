import { RepositoryResponse } from '@/shared/core/either';
import {
  AccountDeletionBlockers,
  PurgeCandidate,
  UserDataExport,
} from '../../types/account.types';

export abstract class AccountLifecycleRepository {
  abstract findDeletionBlockers(userId: string): RepositoryResponse<AccountDeletionBlockers>;
  abstract requestDeletion(userId: string, requestedAt: Date): RepositoryResponse<Date>;
  abstract cancelDeletion(userId: string): RepositoryResponse<void>;
  abstract findPurgeCandidates(purgeBefore: Date): RepositoryResponse<PurgeCandidate[]>;
  abstract purge(userId: string, purgedAt: Date): RepositoryResponse<void>;
  abstract exportData(userId: string): RepositoryResponse<UserDataExport | null>;
}
