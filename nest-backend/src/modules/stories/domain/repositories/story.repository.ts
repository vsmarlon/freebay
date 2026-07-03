import { RepositoryResponse } from '@/shared/core/either';

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

export abstract class StoryRepository {
  abstract findActiveWithViews(): RepositoryResponse<StoryWithViews[]>;
  abstract findByUserId(userId: string): RepositoryResponse<StoryBrief[]>;
  abstract findById(id: string): RepositoryResponse<{ id: string; userId: string; imageUrl: string } | null>;
  abstract create(data: CreateStoryInput): RepositoryResponse<StoryCreatePayload>;
  abstract delete(id: string): RepositoryResponse<void>;
  abstract upsertView(storyId: string, viewerId: string): RepositoryResponse<void>;
}
