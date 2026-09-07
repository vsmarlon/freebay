export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 50;

export interface CursorPage<T> {
  items: T[];
  hasMore: boolean;
  nextCursor: string | null;
}

export interface PageQuery {
  cursor?: string;
  limit: number;
}

export const FIRST_PAGE: PageQuery = { limit: DEFAULT_PAGE_SIZE };

export function pageQuery(raw: { cursor?: string; limit?: number } = {}): PageQuery {
  const cursor = decodeIdCursor(raw.cursor) ?? undefined;
  return { cursor, limit: clampLimit(raw.limit) };
}

export function encodeCursor(payload: Record<string, string | number>): string {
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

export function decodeCursor<T extends Record<string, string | number>>(
  cursor: string | undefined,
): T | null {
  if (!cursor) return null;
  try {
    const decoded = JSON.parse(
      Buffer.from(cursor, 'base64url').toString('utf8'),
    ) as unknown;
    if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) return null;
    return decoded as T;
  } catch {
    return null;
  }
}

export function decodeIdCursor(cursor: string | undefined): string | null {
  const decoded = decodeCursor<{ id?: string }>(cursor);
  return typeof decoded?.id === 'string' ? decoded.id : null;
}

export function decodeOffsetCursor(cursor: string | undefined): number {
  const decoded = decodeCursor<{ offset?: number }>(cursor);
  const offset = decoded?.offset;
  return typeof offset === 'number' && Number.isInteger(offset) && offset >= 0 ? offset : 0;
}

export function clampLimit(limit: number | undefined): number {
  if (!limit || !Number.isInteger(limit) || limit < 1) return DEFAULT_PAGE_SIZE;
  return Math.min(limit, MAX_PAGE_SIZE);
}

export function buildIdCursorPage<T extends { id: string }>(
  rows: T[],
  limit: number,
): CursorPage<T> {
  const hasMore = rows.length > limit;
  const items = hasMore ? rows.slice(0, limit) : rows;
  const last = items[items.length - 1];
  return {
    items,
    hasMore,
    nextCursor: hasMore && last ? encodeCursor({ id: last.id }) : null,
  };
}

export function buildOffsetCursorPage<T>(
  items: T[],
  offset: number,
  limit: number,
  total: number,
): CursorPage<T> {
  const nextOffset = offset + limit;
  const hasMore = nextOffset < total;
  return {
    items,
    hasMore,
    nextCursor: hasMore ? encodeCursor({ offset: nextOffset }) : null,
  };
}

interface KeysetArgs {
  take: number;
  cursor?: { id: string };
  skip?: number;
}

/**
 * Keyset pagination over any Prisma delegate. Over-fetches one row to derive
 * `hasMore` without a second count query. The caller's `orderBy` must end in a
 * unique tiebreaker (usually `id`) or rows can repeat across pages.
 */
export async function paginateById<TRow extends { id: string }, TArgs extends object>(
  findMany: (args: TArgs & KeysetArgs) => Promise<TRow[]>,
  baseArgs: TArgs,
  page: PageQuery,
): Promise<CursorPage<TRow>> {
  const rows = await findMany({
    ...baseArgs,
    take: page.limit + 1,
    ...(page.cursor ? { cursor: { id: page.cursor }, skip: 1 } : {}),
  } as TArgs & KeysetArgs);

  return buildIdCursorPage(rows, page.limit);
}

interface OffsetArgs {
  take: number;
  skip: number;
}

/**
 * Offset pagination behind the same opaque-cursor envelope, for rankings and
 * scored windows where a keyset cursor cannot be derived from a row.
 */
export async function paginateByOffset<TRow, TArgs extends object>(
  findMany: (args: TArgs & OffsetArgs) => Promise<TRow[]>,
  count: () => Promise<number>,
  baseArgs: TArgs,
  raw: { cursor?: string; limit?: number },
): Promise<CursorPage<TRow>> {
  const limit = clampLimit(raw.limit);
  const offset = decodeOffsetCursor(raw.cursor);

  const [items, total] = await Promise.all([
    findMany({ ...baseArgs, take: limit, skip: offset } as TArgs & OffsetArgs),
    count(),
  ]);

  return buildOffsetCursorPage(items, offset, limit, total);
}

export function mapPage<TIn, TOut>(
  page: CursorPage<TIn>,
  map: (item: TIn) => TOut,
): CursorPage<TOut> {
  return { items: page.items.map(map), hasMore: page.hasMore, nextCursor: page.nextCursor };
}
