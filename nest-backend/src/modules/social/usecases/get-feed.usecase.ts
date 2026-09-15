import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import {
  decodeFeedCursor,
  FeedQuery,
  FeedRepositoryQuery,
  FeedResult,
} from '../types/social.types';

@Injectable()
export class GetFeedUseCase {
  constructor(private readonly postRepository: PrismaPostRepository) {}

  async execute(input: FeedQuery): Promise<Either<AppError, FeedResult>> {
    const type = input.type ?? 'explore';
    const contentFilter = input.contentFilter ?? 'all';
    if (type !== 'explore' && type !== 'following') {
      return left(new BadRequestError('Tipo de feed inválido'));
    }
    if (!['all', 'social', 'selling'].includes(contentFilter)) {
      return left(new BadRequestError('Filtro de conteúdo inválido'));
    }

    let cursor;
    if (input.cursor) {
      cursor = decodeFeedCursor(input.cursor);
      if (
        !cursor ||
        cursor.scope !== 'following-feed' ||
        type !== 'following' ||
        cursor.userId !== (input.userId ?? '') ||
        cursor.type !== type ||
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
