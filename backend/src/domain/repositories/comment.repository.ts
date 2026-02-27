import { CommentEntity } from '../entities';

export interface ICommentRepository {
  findByPostId(
    postId: string,
    params: { cursor?: string; limit?: number },
  ): Promise<CommentEntity[]>;
  create(data: { content: string; userId: string; postId: string }): Promise<CommentEntity>;
}
