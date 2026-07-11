import { RepositoryResponse } from '@/shared/core/either';
import { UserBrief } from './follow.repository';

export abstract class BlockRepository {
  abstract block(blockerId: string, blockedId: string): RepositoryResponse<void>;
  abstract unblock(blockerId: string, blockedId: string): RepositoryResponse<void>;
  abstract isBlocked(blockerId: string, blockedId: string): RepositoryResponse<boolean>;
  abstract getBlockedUsers(userId: string, limit: number, offset: number): RepositoryResponse<UserBrief[]>;
}
