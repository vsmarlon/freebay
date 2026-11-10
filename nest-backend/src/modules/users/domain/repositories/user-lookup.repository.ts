import { RepositoryResponse } from '@/shared/core/either';
import { UserLookupRecord } from '../../types/user.types';

/**
 * Narrow domain-facing lookup; the users data layer binds this port to the
 * concrete repository at DI time (see users.module).
 */
export abstract class UserLookupRepository {
  abstract findById(id: string): RepositoryResponse<UserLookupRecord | null>;
}
