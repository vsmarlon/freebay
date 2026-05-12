import { User } from '@prisma/client';

export interface UserResponse {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  bio: string | null;
  city: string | null;
  state: string | null;
  isVerified: boolean;
  reputationScore: number;
  totalReviews: number;
  createdAt: Date;
  hasCpf: boolean;
}

export interface UserStatsResponse {
  salesCount: number;
  purchasesCount: number;
  followersCount: number;
  followingCount: number;
}

export interface FollowResponse {
  following: boolean;
  followersCount: number;
  followingCount: number;
}

export interface BlockResponse {
  blocked: boolean;
}

export interface SearchUserResponse {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  bio: string | null;
  isVerified: boolean;
  reputationScore: number;
  totalReviews: number;
  followersCount: number;
  followingCount: number;
}

export interface SuggestionResponse {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  bio: string | null;
  isVerified: boolean;
  reputationScore: number;
  totalReviews: number;
  followersCount: number;
  followingCount: number;
  mutualCount: number;
}

export const toUserResponse = (user: User): UserResponse => ({
  id: user.id,
  displayName: user.displayName,
  avatarUrl: user.avatarUrl,
  bio: user.bio,
  city: user.city,
  state: user.state,
  isVerified: user.isVerified,
  reputationScore: user.reputationScore,
  totalReviews: user.totalReviews,
  createdAt: user.createdAt,
  hasCpf: !!user.cpf,
});
