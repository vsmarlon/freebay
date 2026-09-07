import { Injectable } from '@nestjs/common';
import { left, right, isLeft } from '@/shared/core/either';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PrismaShareRepository } from '../data/repositories/share-database.repository';
import { SearchPostsQuery } from '../types/social.types';

@Injectable()
export class SearchPostsUseCase {
  constructor(
    private readonly postRepository: PrismaPostRepository,
    private readonly shareRepository: PrismaShareRepository,
  ) {}

  async execute(query: SearchPostsQuery) {
    const result = await this.postRepository.searchPosts(query);
    if (isLeft(result)) return left(result.value);

    const posts = result.value;
    if (!query.userId) return right(posts);

    const repostedMap: Record<string, boolean> = {};
    for (const post of posts) {
      const existsResult = await this.shareRepository.exists(query.userId, post.id);
      if (isLeft(existsResult)) continue;
      repostedMap[post.id] = existsResult.value;
    }

    const postsWithReposted = posts.map(post => ({
      ...post,
      hasReposted: repostedMap[post.id] ?? false,
    }));

    return right(postsWithReposted);
  }
}
