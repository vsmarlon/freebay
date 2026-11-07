export type ChatMessage = {
  id: string;
  conversationId: string;
  senderId: string;
  clientMessageId?: string | null;
  content: string | null;
  type: 'TEXT' | 'IMAGE' | 'VIDEO' | 'AUDIO' | 'GIF' | 'LOCATION' | 'PRODUCT_CARD' | 'DOCUMENT';
  attachmentUrl: string | null;
  metadata: Record<string, unknown> | null;
  replyToId: string | null;
  replyTo?: ChatMessage | null;
  deletedAt: string | null;
  readAt: string | null;
  deliveredAt: string | null;
  createdAt: string;
  viewOnce: boolean;
  reactions?: Array<{ emoji: string; count: number; userIds?: string[] }>;
  pending?: boolean;
};

export type Conversation = {
  id: string;
  threadType: 'DIRECT' | 'ORDER';
  otherUser: { id: string; displayName: string; avatarUrl: string | null };
  lastMessage: { content: string | null; createdAt: string } | null;
  unreadCount: number;
  status: string;
  createdAt: string;
  product?: { id: string; title: string; imageUrl: string | null; status: string };
  orderInfo?: { id: string; productTitle: string; status: string };
  preference?: { isArchived: boolean; theme: string; backgroundUrl: string | null; muted?: boolean } | null;
};

export type CursorPage<T> = { items: T[]; nextCursor: string | null; hasMore: boolean };
export type Transcript = {
  messages: ChatMessage[];
  hasMore: boolean;
  nextCursor: string | null;
  threadType: Conversation['threadType'];
  otherUserId: string;
  otherUser: Conversation['otherUser'];
  preference: { isArchived: boolean; theme: string; backgroundUrl: string | null; muted?: boolean } | null;
};

export function mergeMessages(current: ChatMessage[], incoming: ChatMessage[]): ChatMessage[] {
  const byId = new Map(current.map((message) => [message.id, message]));
  const clientIds = new Map(current.filter((message) => message.clientMessageId).map((message) => [message.clientMessageId!, message.id]));
  for (const message of incoming) {
    const matchedId = clientIds.get(message.clientMessageId ?? '') ?? message.id;
    const previous = byId.get(matchedId);
    if (previous) byId.delete(matchedId);
    byId.set(message.id, { ...previous, ...message, ...(previous?.pending ? { pending: false } : {}) });
    if (message.clientMessageId) clientIds.set(message.clientMessageId, message.id);
  }
  return [...byId.values()].sort((a, b) => a.createdAt.localeCompare(b.createdAt) || a.id.localeCompare(b.id));
}

export function shouldRefreshReadState(event: { conversationId?: unknown; readerId?: unknown }, conversationId: string, userId: string | undefined): boolean {
  return typeof event.conversationId === 'string' && event.conversationId === conversationId && typeof event.readerId === 'string' && event.readerId !== userId;
}

export const CHAT_REACTIONS = ['❤️', '😂', '😮', '😢', '😡', '👍'] as const;
export const CHAT_THEMES = ['DEFAULT', 'CRIMSON', 'COBALT', 'FOREST', 'AMBER', 'SLATE'] as const;
export type MediaKind = 'IMAGE' | 'VIDEO' | 'AUDIO' | 'DOCUMENT';
export type LocationMessageMetadata = { latitude: number; longitude: number; accuracyMeters: number; capturedAt: string; address?: string };
export function hasValidCoordinates(latitude: unknown, longitude: unknown): latitude is number {
  return typeof latitude === 'number' && Number.isFinite(latitude) && latitude >= -90 && latitude <= 90 && typeof longitude === 'number' && Number.isFinite(longitude) && longitude >= -180 && longitude <= 180;
}
export function replyPreview(message: ChatMessage, mediaLabel: string): string | null {
  const reply = message.replyTo;
  if (!reply) return null;
  if (reply.deletedAt || (reply.viewOnce && reply.readAt)) return mediaLabel;
  return reply.content ?? mediaLabel;
}
export function locationMessageMetadata(input: { latitude: string; longitude: string; address: string; accuracyMeters?: number; capturedAt?: string }): LocationMessageMetadata | null {
  if (!input.latitude.trim() || !input.longitude.trim()) return null;
  const latitude = Number(input.latitude);
  const longitude = Number(input.longitude);
  if (input.accuracyMeters === undefined || input.capturedAt === undefined) return null;
  const accuracyMeters = input.accuracyMeters;
  const capturedAt = input.capturedAt;
  const address = input.address.trim();
  if (!hasValidCoordinates(latitude, longitude)) return null;
  if (!Number.isFinite(accuracyMeters) || accuracyMeters < 0 || accuracyMeters > 100_000 || !Number.isFinite(Date.parse(capturedAt)) || new Date(capturedAt).toISOString() !== capturedAt) return null;
  if (input.address.trim() && (!address || address.length > 500)) return null;
  return { latitude, longitude, accuracyMeters, capturedAt, ...(address ? { address } : {}) };
}
export function filterConversations(conversations: Conversation[], threadType: 'ALL' | Conversation['threadType'], unreadOnly: boolean): Conversation[] {
  return conversations.filter((conversation) =>
    (threadType === 'ALL' || conversation.threadType === threadType) &&
    (!unreadOnly || conversation.unreadCount > 0),
  );
}
export const canForwardSelection = (count: number, containsViewOnce: boolean, containsDeleted = false) => count > 0 && count <= 50 && !containsViewOnce && !containsDeleted;
export const shouldFetchMedia = (viewOnce: boolean, explicitlyOpened: boolean) => !viewOnce || explicitlyOpened;

export function mediaMessagePayload(input: { type: MediaKind; attachmentUrl: string; viewOnce?: boolean; durationMs?: number }) {
  return {
    type: input.type,
    attachmentUrl: input.attachmentUrl,
    ...(input.viewOnce ? { viewOnce: true } : {}),
    ...(input.durationMs ? { durationMs: input.durationMs, metadata: { durationMs: input.durationMs } } : {}),
  };
}
