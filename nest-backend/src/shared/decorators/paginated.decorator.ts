import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';
import { PageQuery, pageQuery } from '@/shared/core/pagination';
import { ApiQueryOptions } from '@/shared/swagger/api-doc.decorator';

/**
 * Normalizes `?cursor=&limit=` into a clamped PageQuery with the cursor already
 * decoded. Invalid or absent values fall back to the first page, so a malformed
 * cursor never 500s — it just starts over.
 *
 * Document it on the route with `queries: PAGINATION_QUERIES`.
 */
export const Paginated = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): PageQuery => {
    const request = ctx.switchToHttp().getRequest<Request>();
    const raw = request.query as Record<string, unknown>;
    const limit = Number(raw.limit);

    return pageQuery({
      cursor: typeof raw.cursor === 'string' ? raw.cursor : undefined,
      limit: Number.isFinite(limit) ? limit : undefined,
    });
  },
);

export const PAGINATION_QUERIES: ApiQueryOptions[] = [
  { name: 'cursor', description: 'Opaque cursor from a previous response. Omit for the first page.' },
  { name: 'limit', description: 'Page size, 1-50. Defaults to 20.' },
];
