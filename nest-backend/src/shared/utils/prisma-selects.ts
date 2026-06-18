export const USER_SELECT_MINIMAL = {
  id: true,
  displayName: true,
  avatarUrl: true,
} as const;

export const USER_SELECT_BASIC = {
  id: true,
  displayName: true,
  avatarUrl: true,
  isVerified: true,
} as const;

export const SELLER_SELECT_FULL = {
  id: true,
  displayName: true,
  avatarUrl: true,
  isVerified: true,
  reputationScore: true,
  totalReviews: true,
} as const;
