import { RepositoryResponse } from '@/shared/core/either';
import { UserBrief } from '../../types/user.types';

export abstract class SafetyListRepository {
  abstract candidates(ownerId: string, search: string, selected: boolean, limit: number, offset: number): RepositoryResponse<(UserBrief & { isCloseFriend: boolean })[]>;
  abstract list(ownerId: string, kind: 'closeFriends' | 'restricted', limit: number, offset: number): RepositoryResponse<UserBrief[]>;
  abstract addCloseFriend(ownerId: string, memberId: string): RepositoryResponse<boolean>;
  abstract removeCloseFriend(ownerId: string, memberId: string): RepositoryResponse<void>;
  abstract addRestriction(ownerId: string, restrictedId: string): RepositoryResponse<boolean>;
  abstract removeRestriction(ownerId: string, restrictedId: string): RepositoryResponse<void>;
}
