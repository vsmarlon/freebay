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

export type UserSuggestionResult = UserSearchResult & {
  mutualCount: number;
};

type UserProfileFields = Omit<
  UserSearchResult,
  'followersCount' | 'followingCount'
>;

/// Shapes a user row plus its follow counts into the search/suggestion result type.
export function toUserSearchResult(
  user: UserProfileFields,
  followersCount: number,
  followingCount: number,
): UserSearchResult {
  return {
    id: user.id,
    displayName: user.displayName,
    username: user.username,
    avatarUrl: user.avatarUrl,
    bio: user.bio,
    isVerified: user.isVerified,
    reputationScore: user.reputationScore,
    totalReviews: user.totalReviews,
    followersCount,
    followingCount,
  };
}

export function toUserSuggestionResult(
  user: UserProfileFields,
  followersCount: number,
  followingCount: number,
  mutualCount: number,
): UserSuggestionResult {
  return {
    ...toUserSearchResult(user, followersCount, followingCount),
    mutualCount,
  };
}
