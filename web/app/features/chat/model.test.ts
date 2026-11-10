import { describe, expect, it } from 'vitest';
import {
  canForwardSelection,
  filterConversations,
  locationMessageMetadata,
  mediaMessagePayload,
  mergeMessages,
  replyPreview,
  shouldFetchMedia,
  shouldRefreshReadState,
  type ChatMessage,
  type Conversation,
} from './model';

const message = (id: string, createdAt: string, extra: Partial<ChatMessage> = {}): ChatMessage => ({
  id,
  conversationId: 'conversation',
  senderId: 'user',
  content: id,
  type: 'TEXT',
  attachmentUrl: null,
  metadata: null,
  replyToId: null,
  deletedAt: null,
  readAt: null,
  deliveredAt: null,
  createdAt,
  viewOnce: false,
  ...extra,
});

describe('chat message reconciliation', () => {
  it('replaces an in-flight client message with its HTTP/socket server version without a duplicate', () => {
    const optimistic = message('local', '2026-01-02T00:00:00.000Z', {
      clientMessageId: 'request-1',
      pending: true,
    });
    const delivered = message('server', '2026-01-02T00:00:00.000Z', {
      clientMessageId: 'request-1',
    });

    expect(mergeMessages([optimistic], [delivered])).toEqual([
      { ...optimistic, ...delivered, pending: false },
    ]);
  });

  it('keeps transcript order stable when older pages are prepended and an event repeats an existing ID', () => {
    const first = message('m2', '2026-01-02T00:00:00.000Z');
    const older = message('m1', '2026-01-01T00:00:00.000Z');

    expect(mergeMessages([first], [older, first])).toEqual([older, first]);
  });

  it('emits only supported rich attachment fields and preserves audio duration metadata', () => {
    expect(
      mediaMessagePayload({ type: 'IMAGE', attachmentUrl: '/media/chat/a.jpg', viewOnce: true }),
    ).toEqual({ type: 'IMAGE', attachmentUrl: '/media/chat/a.jpg', viewOnce: true });
    expect(
      mediaMessagePayload({ type: 'AUDIO', attachmentUrl: '/media/chat/a.webm', durationMs: 1200 }),
    ).toEqual({
      type: 'AUDIO',
      attachmentUrl: '/media/chat/a.webm',
      durationMs: 1200,
      metadata: { durationMs: 1200 },
    });
  });

  it('does not authorize a view-once media fetch until an explicit open action', () => {
    expect(shouldFetchMedia(true, false)).toBe(false);
    expect(shouldFetchMedia(true, true)).toBe(true);
    expect(shouldFetchMedia(false, false)).toBe(true);
  });
});

describe('read invalidations', () => {
  it('refreshes canonical state only for another reader in the active conversation', () => {
    expect(
      shouldRefreshReadState({ conversationId: 'active', readerId: 'other' }, 'active', 'me'),
    ).toBe(true);
    expect(
      shouldRefreshReadState({ conversationId: 'active', readerId: 'me' }, 'active', 'me'),
    ).toBe(false);
    expect(
      shouldRefreshReadState({ conversationId: 'stale', readerId: 'other' }, 'active', 'me'),
    ).toBe(false);
    expect(shouldRefreshReadState({ conversationId: 'active' }, 'active', 'me')).toBe(false);
  });
});

describe('inbox local filters', () => {
  it('combines thread type and unread filtering over the loaded conversation pages', () => {
    const conversation = (
      id: string,
      threadType: Conversation['threadType'],
      unreadCount: number,
    ): Conversation => ({
      id,
      threadType,
      otherUser: { id: `user-${id}`, displayName: id, avatarUrl: null },
      lastMessage: null,
      unreadCount,
      status: 'ACCEPTED',
      createdAt: '2026-01-01T00:00:00.000Z',
    });
    const items = [
      conversation('direct-unread', 'DIRECT', 1),
      conversation('direct-read', 'DIRECT', 0),
      conversation('order-unread', 'ORDER', 2),
    ];
    expect(filterConversations(items, 'ALL', true).map((item) => item.id)).toEqual([
      'direct-unread',
      'order-unread',
    ]);
    expect(filterConversations(items, 'DIRECT', false).map((item) => item.id)).toEqual([
      'direct-unread',
      'direct-read',
    ]);
    expect(filterConversations(items, 'ORDER', true).map((item) => item.id)).toEqual([
      'order-unread',
    ]);
    expect(filterConversations(items, 'ALL', false)).toEqual(items);
  });
});

describe('forwarding eligibility', () => {
  it.each([
    [0, false, false, false],
    [1, false, false, true],
    [50, false, false, true],
    [51, false, false, false],
    [1, true, false, false],
    [1, false, true, false],
  ])(
    'accepts only supported ordinary message batches (%i messages, view-once=%s, deleted=%s)',
    (count, viewOnce, deleted, expected) => {
      expect(canForwardSelection(count, viewOnce, deleted)).toBe(expected);
    },
  );
});

describe('measured location metadata', () => {
  const validInput = {
    latitude: '0',
    longitude: '0',
    address: '',
    accuracyMeters: 12,
    capturedAt: '2026-10-08T12:00:00.000Z',
  };

  it.each([
    ['equator and prime meridian', '0', '0'],
    ['southwest coordinate limits', '-90', '-180'],
    ['northeast coordinate limits', '90', '180'],
  ])('preserves valid finite coordinates at %s', (_partition, latitude, longitude) => {
    expect(locationMessageMetadata({ ...validInput, latitude, longitude })).toMatchObject({
      latitude: Number(latitude),
      longitude: Number(longitude),
      accuracyMeters: 12,
      capturedAt: validInput.capturedAt,
    });
  });

  it.each([
    ['', '0'],
    ['Infinity', '0'],
    ['-90.0001', '0'],
    ['90.0001', '0'],
    ['0', '-180.0001'],
    ['0', '180.0001'],
    ['0', 'NaN'],
  ])('rejects missing, non-finite, or out-of-range coordinates (%s, %s)', (latitude, longitude) => {
    expect(locationMessageMetadata({ ...validInput, latitude, longitude })).toBeNull();
  });

  it('trims optional place text into the backend address field and rejects overlong text', () => {
    expect(locationMessageMetadata({ ...validInput, address: '  Ferry terminal  ' })?.address).toBe(
      'Ferry terminal',
    );
    expect(locationMessageMetadata({ ...validInput, address: 'x'.repeat(501) })).toBeNull();
  });

  it('rejects coordinates without measured accuracy and timestamp', () => {
    expect(locationMessageMetadata({ latitude: '1', longitude: '2', address: '' })).toBeNull();
    expect(
      locationMessageMetadata({ latitude: '1', longitude: '2', address: '', accuracyMeters: 5 }),
    ).toBeNull();
  });
});

describe('reply privacy', () => {
  const parent = (overrides: Partial<ChatMessage> = {}): ChatMessage => ({
    id: 'parent',
    conversationId: 'conversation',
    senderId: 'other',
    content: 'private text',
    type: 'TEXT',
    attachmentUrl: null,
    metadata: null,
    replyToId: null,
    deletedAt: null,
    readAt: null,
    deliveredAt: null,
    createdAt: '2026-10-08T12:00:00.000Z',
    viewOnce: false,
    ...overrides,
  });
  const message = (): ChatMessage => ({
    ...parent({ id: 'reply', content: 'reply' }),
    replyTo: parent(),
  });

  it('keeps live ordinary parent text visible', () => {
    expect(replyPreview(message(), 'Media')).toBe('private text');
  });

  it('redacts deleted and already-opened view-once parents', () => {
    expect(
      replyPreview(
        { ...message(), replyTo: parent({ deletedAt: '2026-10-08T12:01:00.000Z' }) },
        'Media',
      ),
    ).toBe('Media');
    expect(
      replyPreview(
        { ...message(), replyTo: parent({ viewOnce: true, readAt: '2026-10-08T12:01:00.000Z' }) },
        'Media',
      ),
    ).toBe('Media');
  });
});
