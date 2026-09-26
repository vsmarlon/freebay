import { RepositoryResponse } from '@/shared/core/either';

export abstract class BlockRepository {
  abstract isBlocked(blockerId: string, blockedId: string): RepositoryResponse<boolean>;
  abstract block(blockerId: string, blockedId: string): RepositoryResponse<void>;
  abstract unblock(blockerId: string, blockedId: string): RepositoryResponse<void>;
}
