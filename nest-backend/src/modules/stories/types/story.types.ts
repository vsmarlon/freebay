export interface StoryWithViews {
  id: string;
  userId: string;
  imageUrl: string;
  createdAt: Date;
  expiresAt: Date;
  user: { id: string; displayName: string; avatarUrl: string | null };
  _count: { views: number };
}

export interface StoryBrief {
  id: string;
  imageUrl: string;
  createdAt: Date;
  expiresAt: Date;
}

export interface CreateStoryInput {
  imageUrl: string;
  expiresAt: Date;
  user: { connect: { id: string } };
}

export interface StoryCreatePayload {
  id: string;
  userId: string;
  imageUrl: string;
  expiresAt: Date;
  createdAt: Date;
  user: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
}
