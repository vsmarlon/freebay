import { PostEntity } from '../entities';

export interface IPostRepository {
  findById(id: string): Promise<PostEntity | null>;
  findByUserId(userId: string, params: { cursor?: string; limit?: number }): Promise<PostEntity[]>;
  findFeed(params: { userId: string; cursor?: string; limit?: number }): Promise<PostEntity[]>;
  create(
    data: Omit<
      PostEntity,
      'id' | 'createdAt' | 'updatedAt' | 'likesCount' | 'commentsCount' | 'sharesCount'
    >,
  ): Promise<PostEntity>;
  delete(id: string): Promise<void>;
  incrementLikes(id: string): Promise<void>;
  decrementLikes(id: string): Promise<void>;
  incrementComments(id: string): Promise<void>;
  incrementShares(id: string): Promise<void>;
}
