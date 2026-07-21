export type UserSearchResult = {
  id: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  bio: string | null;
  isVerified: boolean;
  reputationScore: number;
  totalReviews: number;
  followersCount: number;
  followingCount: number;
};

export type UserSuggestionResult = {
  id: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  bio: string | null;
  isVerified: boolean;
  reputationScore: number;
  totalReviews: number;
  followersCount: number;
  followingCount: number;
  mutualCount: number;
};
