import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import {
  decodeFeedCursor,
  FeedQuery,
  FeedRepositoryQuery,
  FeedResult,
  ContentFilter,
  FeedType,
} from '../types/social.types';

@Injectable()
export class GetFeedUseCase {
  constructor(private readonly postRepository: PrismaPostRepository) {}

  async execute(input: FeedQuery): Promise<Either<AppError, FeedResult>> {
    const type = input.type ?? FeedType.EXPLORE;
    const contentFilter = input.contentFilter ?? ContentFilter.ALL;
    if (type !== FeedType.EXPLORE && type !== FeedType.FOLLOWING) {
      return left(new BadRequestError('Tipo de feed inválido'));
    }
    if (contentFilter !== ContentFilter.ALL && contentFilter !== ContentFilter.SOCIAL && contentFilter !== ContentFilter.SELLING) {
      return left(new BadRequestError('Filtro de conteúdo inválido'));
    }

    let cursor;
    if (type === FeedType.EXPLORE && input.offset && input.offset > 0) {
      return left(new BadRequestError('Use o cursor para paginar o feed'));
    }
    if (input.cursor) {
      cursor = decodeFeedCursor(input.cursor);
      if (
        !cursor ||
        cursor.type !== type ||
        cursor.userId !== (input.userId ?? '') ||
        cursor.contentFilter !== contentFilter
      ) {
        return left(new BadRequestError('Cursor inválido para este feed'));
      }
    }

    const query: FeedRepositoryQuery = {
      ...input,
      type,
      contentFilter,
      cursor,
    };
    const result = await this.postRepository.findFeed(query);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
