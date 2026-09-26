import { Injectable } from '@nestjs/common';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { CursorPage } from '@/shared/core/pagination';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { ProfileTimelineCursor, UserPostEntry, UserPostsQuery } from '../types/social.types';

@Injectable()
export class GetProfileTimelineUseCase {
  constructor(private readonly posts: PrismaPostRepository) {}

  async execute(query: UserPostsQuery): Promise<Either<AppError, CursorPage<UserPostEntry>>> {
    const [owner, at, eventId, extra] = query.cursor
      ? Buffer.from(query.cursor, 'base64url').toString('utf8').split('|')
      : [];
    if (query.cursor && (owner !== query.userId || !at || Number.isNaN(Date.parse(at)) || !eventId || extra)) {
      return left(new BadRequestError('Cursor inválido'));
    }
    const cursor: ProfileTimelineCursor | undefined = at && eventId ? { createdAt: at, eventId } : undefined;
    const result = await this.posts.findTimelineByUserId({
      userId: query.userId, viewerId: query.viewerId, limit: query.limit ?? 20, cursor,
    });
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
