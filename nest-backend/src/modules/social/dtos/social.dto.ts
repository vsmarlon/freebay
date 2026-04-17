import { z } from 'zod';

export const createPostSchema = z.object({
  content: z.string().optional(),
  imageUrl: z.string().optional(),
  type: z.enum(['PRODUCT', 'REGULAR']),
});

export const createCommentSchema = z.object({
  content: z.string().min(1).max(1000),
  parentId: z.string().uuid().optional(),
});

export const createStorySchema = z.object({
  imageBase64: z.string(),
});

export type CreatePostDTO = z.infer<typeof createPostSchema>;
export type CreateCommentDTO = z.infer<typeof createCommentSchema>;
export type CreateStoryDTO = z.infer<typeof createStorySchema>;

export interface CreatePostInput {
  userId: string;
  content?: string;
  imageUrl?: string;
  type: 'PRODUCT' | 'REGULAR';
}

export interface CreatePostOutput {
  id: string;
  content: string | null;
  imageUrl: string | null;
  type: 'PRODUCT' | 'REGULAR';
  userId: string;
  createdAt: Date;
}

export interface LikePostInput {
  userId: string;
  postId: string;
}

export interface CreateCommentInput {
  userId: string;
  postId: string;
  content: string;
  parentId?: string;
}

export interface CreateCommentOutput {
  id: string;
  postId: string;
  userId: string;
  content: string;
  createdAt: Date;
}

export interface CreateStoryInput {
  userId: string;
  imageBase64: string;
}

export interface CreateStoryOutput {
  id: string;
  userId: string;
  imageUrl: string;
  createdAt: Date;
}
