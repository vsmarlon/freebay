import { Injectable } from '@nestjs/common';
import { left, right } from '@/shared/core/either';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { SearchPostsQuery } from '../types/social.types';

@Injectable()
export class SearchPostsUseCase {
  constructor(private readonly postRepository: PrismaPostRepository) {}

  async execute(query: SearchPostsQuery) {
    const result = await this.postRepository.searchPosts(query);
    if (result.isLeft()) return left(result.value);

    return right(result.value);
  }
}
