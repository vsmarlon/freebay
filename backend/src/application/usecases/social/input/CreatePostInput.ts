export interface CreatePostInput {
  content: string | null;
  imageUrl?: string | null;
  type: 'PRODUCT' | 'REGULAR';
  userId: string;
}
