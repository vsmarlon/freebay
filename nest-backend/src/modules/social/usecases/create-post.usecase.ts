import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';
import { CreatePostInput, CreatePostOutput } from '../dtos/social.dto';

@Injectable()
export class CreatePostUseCase {
  constructor(private readonly postRepository: PostRepository) {}

  async execute(input: CreatePostInput): Promise<Either<AppError, CreatePostOutput>> {
    const result = await this.postRepository.create({
      content: input.content ?? null,
      imageUrl: input.imageUrl ?? null,
      type: input.type,
      user: { connect: { id: input.userId } },
    });
    if (isLeft(result)) return left(result.value);

    const post = result.value;
    return right({
      id: post.id,
      content: post.content,
      imageUrl: post.imageUrl,
      type: post.type as 'PRODUCT' | 'REGULAR',
      userId: post.userId,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      sharesCount: post.sharesCount,
      createdAt: post.createdAt,
      user: post.user,
    });
  }
}
