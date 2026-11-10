export interface UserLookupRecord {
  id: string;
}

export enum SafetyListKind {
  CLOSE_FRIENDS = 'closeFriends',
  RESTRICTED = 'restricted',
}

export type UserBrief = {
  id: string;
  displayName: string;
  username?: string | null;
  avatarUrl: string | null;
  avatarBlurHash?: string | null;
  isVerified: boolean;
  reputationScore: number;
};
