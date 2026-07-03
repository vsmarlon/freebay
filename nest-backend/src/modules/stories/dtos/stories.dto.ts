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
