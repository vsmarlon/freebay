import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../repositories/social.repository';
import { CreatePostInput, CreatePostOutput } from '../dtos/social.dto';

@Injectable()
export class CreatePostUseCase {
  constructor(private postRepository: PrismaPostRepository) {}

  async execute(input: CreatePostInput): Promise<Either<AppError, CreatePostOutput>> {
    const post = await this.postRepository.create({
      content: input.content ?? null,
      imageUrl: input.imageUrl ?? null,
      type: input.type,
      user: { connect: { id: input.userId } },
    });

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
