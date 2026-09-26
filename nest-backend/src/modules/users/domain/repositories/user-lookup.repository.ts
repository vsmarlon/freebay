import { RepositoryResponse } from '@/shared/core/either';
import { User } from '@prisma/client';

export abstract class UserLookupRepository {
  abstract findById(id: string): RepositoryResponse<User | null>;
}
