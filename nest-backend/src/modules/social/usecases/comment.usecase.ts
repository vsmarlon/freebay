import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';
import { CommentRepository } from '../domain/repositories/comment.repository';
import { CreateCommentInput, CreateCommentOutput } from '../dtos/social.dto';

@Injectable()
export class CommentUseCase {
  constructor(
    private readonly commentRepository: CommentRepository,
    private readonly postRepository: PostRepository,
  ) {}

  async execute(input: CreateCommentInput): Promise<Either<AppError, CreateCommentOutput>> {
    const result = await this.commentRepository.create({
      content: input.content,
      post: { connect: { id: input.postId } },
      user: { connect: { id: input.userId } },
      ...(input.parentId ? { parent: { connect: { id: input.parentId } } } : {}),
    });
    if (isLeft(result)) return left(result.value);

    await this.postRepository.update(input.postId, { commentsCount: { increment: 1 } });

    return right({
      id: result.value.id,
      postId: input.postId,
      userId: input.userId,
      content: input.content,
      createdAt: result.value.createdAt,
    });
  }
}
