import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError, BadRequestError } from "@/shared/core/errors";
import { CursorPage } from "@/shared/core/pagination";
import { PrismaPostRepository } from "../data/repositories/post-database.repository";
import {
  UserPostEntry,
  UserPostsCursor,
  UserPostsQuery,
} from "../types/social.types";

@Injectable()
export class GetUserPostsUseCase {
  constructor(private readonly postRepository: PrismaPostRepository) {}

  async execute(
    query: UserPostsQuery,
  ): Promise<Either<AppError, CursorPage<UserPostEntry>>> {
    const cursor = parseCursor(query.cursor, query.userId);
    if (cursor.isLeft()) return left(cursor.value);

    const ownResult = await this.postRepository.findByUserId({
      userId: query.userId,
      viewerId: query.viewerId,
      limit: query.limit,
      cursor: cursor.value,
    });
    if (ownResult.isLeft()) return left(ownResult.value);

    const ownPosts: UserPostEntry[] = ownResult.value.items.map((p) => ({
      post: p,
      repostId: null,
      repostedAt: null,
      repostedBy: null,
      isReposted: false,
      sharesCount: p.sharesCount,
    }));
    return right({
      items: ownPosts,
      hasMore: ownResult.value.hasMore,
      nextCursor: ownResult.value.nextCursor,
    });
  }
}

function parseCursor(
  rawCursor: string | undefined,
  profileUserId: string,
): Either<AppError, UserPostsCursor | undefined> {
  if (!rawCursor) return right(undefined);

  try {
    const parsed: unknown = JSON.parse(
      Buffer.from(rawCursor, "base64url").toString("utf8"),
    );
    if (!isCursorPayload(parsed)) return left(new BadRequestError("Cursor inválido"));
    if (parsed.scope !== "user-posts" || parsed.profileUserId !== profileUserId) {
      return left(new BadRequestError("Cursor não pertence a este perfil"));
    }
    const createdAt = new Date(parsed.createdAt);
    if (Number.isNaN(createdAt.getTime())) {
      return left(new BadRequestError("Cursor inválido"));
    }
    return right(parsed);
  } catch {
    return left(new BadRequestError("Cursor inválido"));
  }
}

function isCursorPayload(value: unknown): value is UserPostsCursor {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  const payload: Record<string, unknown> = Object.fromEntries(
    Object.entries(value),
  );
  return (
    typeof payload.scope === "string" &&
    typeof payload.profileUserId === "string" &&
    typeof payload.createdAt === "string" &&
    typeof payload.postId === "string" &&
    payload.scope === "user-posts" &&
    payload.profileUserId.length > 0 &&
    payload.postId.length > 0
  );
}
