import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository, UserPostsQuery } from '../domain/repositories/post.repository';
import { ShareRepository } from '../domain/repositories/share.repository';
import { UserPostEntry } from '../types/social.types';

@Injectable()
export class GetUserPostsUseCase {
  constructor(
    private readonly postRepository: PostRepository,
    private readonly shareRepository: ShareRepository,
  ) {}

  async execute(query: UserPostsQuery): Promise<Either<AppError, UserPostEntry[]>> {
    const ownResult = await this.postRepository.findByUserId(query);
    if (isLeft(ownResult)) return left(ownResult.value);

    const repostResult = await this.shareRepository.findPostsRepostedByUser(query.userId, {
      limit: query.limit,
      cursor: query.cursor,
    });
    if (isLeft(repostResult)) return left(repostResult.value);

    const ownPosts: UserPostEntry[] = ownResult.value.map(p => ({
      post: p,
      repostedAt: null,
      repostedBy: null,
      isReposted: false,
      sharesCount: p.sharesCount,
    }));

    const repostedPosts: UserPostEntry[] = repostResult.value.map(s => ({
      post: s.post,
      repostedAt: s.createdAt,
      repostedBy: s.user,
      isReposted: true,
      sharesCount: s.post.sharesCount,
    }));

    const merged = [...ownPosts, ...repostedPosts];
    merged.sort((a, b) => {
      const aDate = a.repostedAt ?? a.post.createdAt;
      const bDate = b.repostedAt ?? b.post.createdAt;
      return bDate.getTime() - aDate.getTime();
    });

    return right(merged.slice(0, query.limit ?? 20));
  }
}
