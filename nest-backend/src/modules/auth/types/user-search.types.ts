export type UserSearchResult = {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  bio: string | null;
  isVerified: boolean;
  reputationScore: number;
  totalReviews: number;
  _count: { followers: number; following: number };
};

export type UserSuggestionResult = {
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
};
