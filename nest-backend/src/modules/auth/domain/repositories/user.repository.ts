import { RepositoryResponse } from '@/shared/core/either';
import { User, Prisma } from '@prisma/client';
import { UserSearchResult, UserSuggestionResult, UserProfileCounts } from '../../types/user.types';

export abstract class UserRepository {
  abstract findById(id: string): RepositoryResponse<User | null>;
  abstract findByEmail(email: string): RepositoryResponse<User | null>;
  abstract findByGoogleId(googleId: string): RepositoryResponse<User | null>;
  abstract findByUsername(username: string): RepositoryResponse<User | null>;
  abstract create(data: Prisma.UserCreateInput): RepositoryResponse<User>;
  abstract update(id: string, data: Prisma.UserUpdateInput): RepositoryResponse<User>;
  abstract searchUsers(query: string, limit: number, offset: number, viewerId?: string): RepositoryResponse<UserSearchResult[]>;
  abstract getSuggestions(userId: string, limit: number): RepositoryResponse<UserSuggestionResult[]>;
  abstract getProfileCounts(userId: string): RepositoryResponse<UserProfileCounts>;
  abstract findPaymentInfo(userId: string): RepositoryResponse<{ displayName: string; email: string; cpf: string | null } | null>;
}
