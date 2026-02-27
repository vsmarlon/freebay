import { ICommentRepository, IPostRepository } from '@/domain/repositories';
import { CommentEntity } from '@/domain/entities';
import { Either, left, right } from '@/domain/either';
import { AppError, NotFoundError } from '@/domain/errors';

export class CreateCommentUseCase {
  constructor(
    private commentRepository: ICommentRepository,
    private postRepository: IPostRepository,
  ) {}

  async execute(input: {
    content: string;
    userId: string;
    postId: string;
  }): Promise<Either<AppError, CommentEntity>> {
    const post = await this.postRepository.findById(input.postId);
    if (!post) {
      return left(new NotFoundError('Post'));
    }

    const comment = await this.commentRepository.create({
      content: input.content,
      userId: input.userId,
      postId: input.postId,
    });

    await this.postRepository.incrementComments(input.postId);

    return right(comment);
  }
}

export class GetCommentsUseCase {
  constructor(private commentRepository: ICommentRepository) {}

  async execute(
    postId: string,
    params: { cursor?: string; limit?: number },
  ): Promise<Either<AppError, CommentEntity[]>> {
    const comments = await this.commentRepository.findByPostId(postId, params);
    return right(comments);
  }
}
