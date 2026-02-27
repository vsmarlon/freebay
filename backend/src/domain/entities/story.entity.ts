export interface StoryUser {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  isVerified: boolean;
}

export interface StoryEntity {
  id: string;
  userId: string;
  imageUrl: string;
  expiresAt: Date;
  createdAt: Date;
  user: StoryUser;
  isViewed: boolean;
}

export interface StoryViewEntity {
  id: string;
  storyId: string;
  viewerId: string;
  viewedAt: Date;
}
