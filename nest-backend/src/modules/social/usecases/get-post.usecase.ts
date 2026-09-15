import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PostResponse } from '../types/social.types';

@Injectable()
export class GetPostUseCase {
  constructor(private readonly postRepository: PrismaPostRepository) {}

  async execute(input: { id: string; viewerId?: string }): Promise<Either<AppError, PostResponse>> {
    const result = await this.postRepository.findById(input.id, input.viewerId);
    if (result.isLeft()) return left(result.value);
    if (!result.value) return left(new NotFoundError('Post'));
    return right(result.value);
  }
}
