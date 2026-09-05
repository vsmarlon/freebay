import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';

export interface DeletePostInput {
  postId: string;
  userId: string;
}

@Injectable()
export class DeletePostUseCase {
  constructor(private readonly postRepository: PostRepository) {}

  async execute(input: DeletePostInput): Promise<Either<AppError, void>> {
    const post = await this.postRepository.findById(input.postId);
    if (post.isLeft()) return left(post.value);
    if (!post.value) return left(new NotFoundError('Post'));

    if (post.value.userId !== input.userId) {
      return left(new ForbiddenError('Você não tem permissão para excluir este post'));
    }

    const deleteResult = await this.postRepository.softDelete(input.postId);
    if (deleteResult.isLeft()) return left(deleteResult.value);

    return right(undefined);
  }
}
