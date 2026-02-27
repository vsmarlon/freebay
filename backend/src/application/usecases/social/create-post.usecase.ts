import { IPostRepository } from '@/domain/repositories';
import { PostEntity } from '@/domain/entities';
import { Either, right, left } from '@/domain/either';
import { AppError, NotFoundError } from '@/domain/errors';
import { CreatePostInput } from './input/CreatePostInput';

export class CreatePostUseCase {
  constructor(private postRepository: IPostRepository) {}

  async execute(input: CreatePostInput): Promise<Either<AppError, PostEntity>> {
    const post = await this.postRepository.create({
      content: input.content,
      imageUrl: input.imageUrl ?? null,
      type: input.type,
      userId: input.userId,
    });
    return right(post);
  }
}

export class GetPostByIdUseCase {
  constructor(private postRepository: IPostRepository) {}

  async execute(id: string): Promise<Either<AppError, PostEntity>> {
    const post = await this.postRepository.findById(id);
    if (!post) {
      return left(new NotFoundError('Post'));
    }
    return right(post);
  }
}

export class GetFeedUseCase {
  constructor(private postRepository: IPostRepository) {}

  async execute(params: {
    userId: string;
    cursor?: string;
    limit?: number;
  }): Promise<Either<AppError, PostEntity[]>> {
    const posts = await this.postRepository.findFeed(params);
    return right(posts);
  }
}
