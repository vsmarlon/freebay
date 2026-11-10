import { describe, expect, it } from 'vitest';
import { notificationDestination } from './notification-destination';

describe('notification destinations', () => {
  it('builds an internal route only from a supported resource id', () => {
    expect(notificationDestination({ postId: 'post-1' })).toBe('posts/post-1');
  });

  it('maps the mobile notification types to their existing app destinations', () => {
    expect(notificationDestination({ type: 'PAYMENT' })).toBe('wallet');
    expect(notificationDestination({ type: 'ORDER', orderId: 'order-1' })).toBe('orders/order-1');
    expect(notificationDestination({ type: 'MESSAGE', conversationId: 'thread-1' })).toBe(
      'messages/thread-1',
    );
    expect(notificationDestination({ type: 'FOLLOW', senderId: 'user-1' })).toBe('people/user-1');
    expect(notificationDestination({ type: 'DISPUTE', disputeId: 'dispute-1' })).toBe(
      'disputes/dispute-1',
    );
    expect(notificationDestination({ type: 'MENTION', postId: 'post-2' })).toBe('posts/post-2');
    expect(notificationDestination({ action: 'story', storyId: 'story-1' })).toBe(
      'stories/story-1',
    );
    expect(notificationDestination({ action: 'highlight', highlightId: 'highlight-1' })).toBe(
      'highlights/highlight-1',
    );
  });

  it('ignores externally supplied or malformed destinations', () => {
    expect(
      notificationDestination({ url: 'https://attacker.invalid', href: '//attacker.invalid' }),
    ).toBeNull();
    expect(notificationDestination({ productId: 'javascript:alert(1)' })).toBeNull();
    expect(notificationDestination({ action: 'post', postId: '//attacker.invalid' })).toBeNull();
    expect(notificationDestination(null)).toBeNull();
  });
});
