import { Injectable } from '@nestjs/common';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { CursorPage } from '@/shared/core/pagination';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { ProfileTimelineCursor, ProfileTimelineKind, UserPostEntry, UserPostsQuery } from '../types/social.types';

@Injectable()
export class GetProfileTimelineUseCase {
  constructor(private readonly posts: PrismaPostRepository) {}

  async execute(query: UserPostsQuery): Promise<Either<AppError, CursorPage<UserPostEntry>>> {
    const [owner, at, eventId, cursorKind, extra] = query.cursor
      ? Buffer.from(query.cursor, 'base64url').toString('utf8').split('|')
      : [];
    if (query.cursor && (owner !== query.userId || !at || Number.isNaN(Date.parse(at)) || !eventId || extra ||
      (cursorKind && !isTimelineKind(cursorKind)) || cursorKind !== query.kind)) {
      return left(new BadRequestError('Cursor inválido'));
    }
    const cursor: ProfileTimelineCursor | undefined = at && eventId ? {
      createdAt: at, eventId, ...(cursorKind && isTimelineKind(cursorKind) ? { kind: cursorKind } : {}),
    } : undefined;
    const result = await this.posts.findTimelineByUserId({
      userId: query.userId, viewerId: query.viewerId, limit: query.limit ?? 20, cursor, kind: query.kind,
    });
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}

function isTimelineKind(value: string): value is ProfileTimelineKind {
  return Object.values(ProfileTimelineKind).some((kind) => kind === value);
}
