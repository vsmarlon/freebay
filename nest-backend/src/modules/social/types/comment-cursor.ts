export enum CommentCursorScope {
  CONVERSATION = 'conversation',
  CONTEXT_REPLIES = 'context-replies',
  CONTEXT_ANCESTORS = 'context-ancestors',
}

export enum CommentSort {
  RECENT = 'recent',
  LIKES = 'likes',
}

export interface CommentCursor {
  scope: CommentCursorScope;
  ownerId: string;
  viewerId: string;
  sort: CommentSort;
  id: string;
  createdAt: string;
  likesCount: number;
}

export function encodeCommentCursor(cursor: CommentCursor): string {
  return Buffer.from(JSON.stringify(cursor)).toString('base64url');
}

export function decodeCommentCursor(value: string): CommentCursor | null {
  if (value.length > 4096) return null;
  try {
    const parsed: unknown = JSON.parse(Buffer.from(value, 'base64url').toString('utf8'));
    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) return null;
    const data = parsed as Record<string, unknown>;
    if ((data.scope !== CommentCursorScope.CONVERSATION && data.scope !== CommentCursorScope.CONTEXT_REPLIES && data.scope !== CommentCursorScope.CONTEXT_ANCESTORS) ||
      typeof data.ownerId !== 'string' || typeof data.viewerId !== 'string' ||
      (data.sort !== CommentSort.RECENT && data.sort !== CommentSort.LIKES) || typeof data.id !== 'string' ||
      typeof data.createdAt !== 'string' || Number.isNaN(Date.parse(data.createdAt)) ||
      typeof data.likesCount !== 'number' || !Number.isInteger(data.likesCount) || data.likesCount < 0) return null;
    return {
      scope: data.scope,
      ownerId: data.ownerId,
      viewerId: data.viewerId,
      sort: data.sort,
      id: data.id,
      createdAt: data.createdAt,
      likesCount: data.likesCount,
    };
  } catch {
    return null;
  }
}
