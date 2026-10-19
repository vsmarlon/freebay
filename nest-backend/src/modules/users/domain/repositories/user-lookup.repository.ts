import { RepositoryResponse } from '@/shared/core/either';

/**
 * Narrow domain-facing lookup; the users data layer binds this port to the
 * concrete repository at DI time (see users.module).
 */
export interface UserLookupRecord {
  id: string;
}

export abstract class UserLookupRepository {
  abstract findById(id: string): RepositoryResponse<UserLookupRecord | null>;
}
