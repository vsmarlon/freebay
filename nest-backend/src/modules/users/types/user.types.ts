export type UserBrief = {
  id: string;
  displayName: string;
  username?: string | null;
  avatarUrl: string | null;
  avatarBlurHash?: string | null;
  isVerified: boolean;
  reputationScore: number;
};
