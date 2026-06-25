import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaCommentRepository, PrismaPostRepository } from '../repositories/social.repository';
import { CreateCommentInput, CreateCommentOutput } from '../dtos/social.dto';

@Injectable()
export class CommentUseCase {
  constructor(
    private commentRepository: PrismaCommentRepository,
    private postRepository: PrismaPostRepository,
  ) {}

  async execute(input: CreateCommentInput): Promise<Either<AppError, CreateCommentOutput>> {
    const comment = await this.commentRepository.create({
      content: input.content,
      post: { connect: { id: input.postId } },
      user: { connect: { id: input.userId } },
    });

    await this.postRepository.incrementCommentsCount(input.postId);

    return right({
      id: comment.id,
      postId: input.postId,
      userId: input.userId,
      content: input.content,
      createdAt: comment.createdAt,
    });
  }
}
