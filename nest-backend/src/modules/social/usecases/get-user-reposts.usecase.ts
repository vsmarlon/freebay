import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError } from "@/shared/core/errors";
import { PrismaShareRepository } from "../data/repositories/share-database.repository";
import { UserPostEntry, UserPostsQuery } from "../types/social.types";

@Injectable()
export class GetUserRepostsUseCase {
  constructor(private readonly shareRepository: PrismaShareRepository) {}

  async execute(
    query: UserPostsQuery,
  ): Promise<Either<AppError, UserPostEntry[]>> {
    const result = await this.shareRepository.findPostsRepostedByUser(
      query.userId,
      {
        viewerId: query.viewerId,
        limit: query.limit,
        cursor: query.cursor,
      },
    );
    if (result.isLeft()) return left(result.value);

    return right(
      result.value.map((share) => ({
        post: share.post,
        repostId: share.id,
        repostedAt: share.createdAt,
        repostedBy: share.user,
        isReposted: true,
        sharesCount: share.post.sharesCount,
      })),
    );
  }
}
