import { RepositoryResponse } from '@/shared/core/either';
import { User, Prisma } from '@prisma/client';
import { UserSearchResult, UserSuggestionResult } from '../../types/user-search.types';

export abstract class UserRepository {
  abstract findById(id: string): RepositoryResponse<User | null>;
  abstract findByEmail(email: string): RepositoryResponse<User | null>;
  abstract findByUsername(username: string): RepositoryResponse<User | null>;
  abstract create(data: Prisma.UserCreateInput): RepositoryResponse<User>;
  abstract update(id: string, data: Prisma.UserUpdateInput): RepositoryResponse<User>;
  abstract searchUsers(query: string, limit: number, offset: number, viewerId?: string): RepositoryResponse<UserSearchResult[]>;
  abstract getSuggestions(userId: string, limit: number): RepositoryResponse<UserSuggestionResult[]>;
  abstract findPaymentInfo(userId: string): RepositoryResponse<{ displayName: string; email: string; cpf: string | null } | null>;
}
