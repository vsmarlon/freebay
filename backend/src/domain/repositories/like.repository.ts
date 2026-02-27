import { LikeEntity } from '../entities';

export interface ILikeRepository {
  findByUserAndPost(userId: string, postId: string): Promise<LikeEntity | null>;
  create(userId: string, postId: string): Promise<LikeEntity>;
  delete(userId: string, postId: string): Promise<void>;
}
