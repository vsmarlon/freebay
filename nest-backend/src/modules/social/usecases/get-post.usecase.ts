import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PostPayload } from '../types/social.types';

@Injectable()
export class GetPostUseCase {
  constructor(private readonly postRepository: PrismaPostRepository) {}

  async execute(id: string): Promise<Either<AppError, PostPayload>> {
    const result = await this.postRepository.findById(id);
    if (isLeft(result)) return left(result.value);
    if (!result.value) return left(new NotFoundError('Post'));
    return right(result.value);
  }
}
