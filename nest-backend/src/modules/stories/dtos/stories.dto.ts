export interface CreateStoryInput {
  userId: string;
  imageBase64: string;
}

export interface CreateStoryOutput {
  id: string;
  userId: string;
  imageUrl: string;
  expiresAt: Date;
  createdAt: Date;
  user: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
}

export interface GroupedStory {
  user: { id: string; displayName: string; avatarUrl: string | null };
  stories: {
    id: string;
    imageUrl: string;
    createdAt: Date;
    expiresAt: Date;
    viewsCount: number;
  }[];
}
