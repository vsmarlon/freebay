import { pathsFor } from '../../core/routes';

function isRecord(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

export function notificationDestination(data: unknown): string | null {
  if (!isRecord(data)) return null;
  const value = data;
  const id = (...keys: string[]) => {
    for (const key of keys) {
      const candidate = value[key];
      if (typeof candidate === 'string' && /^[A-Za-z0-9_-]+$/.test(candidate)) return candidate;
    }
    return null;
  };
  const action = typeof value.action === 'string' ? value.action : undefined;
  const type = typeof value.type === 'string' ? value.type : undefined;
  const typeAction: Record<string, string> = { PAYMENT: 'wallet', ORDER: 'orders', MESSAGE: 'chat', FOLLOW: 'profile', DISPUTE: 'disputes', MENTION: 'post' };
  const routeAction = action ?? (type ? typeAction[type] : undefined);
  if (routeAction === 'story') { const storyId = id('storyId'); return storyId ? pathsFor.story(storyId) : null; }
  if (routeAction === 'highlight') { const highlightId = id('highlightId'); return highlightId ? pathsFor.highlights(highlightId) : null; }
  switch (routeAction) {
    case 'wallet': return pathsFor.wallet;
    case 'orders': { const orderId = id('orderId'); return orderId ? pathsFor.order(orderId) : null; }
    case 'chat': { const hasThreadId = value.conversationId !== undefined || value.orderId !== undefined; const threadId = id('conversationId', 'orderId'); return threadId ? pathsFor.conversation(threadId) : hasThreadId ? null : pathsFor.messages; }
    case 'profile': { const userId = id(action ? 'userId' : 'senderId', 'userId'); return userId ? pathsFor.person(userId) : null; }
    case 'post': { const postId = id('postId'); return postId ? pathsFor.post(postId) : null; }
    case 'disputes': { const disputeId = id('disputeId'); if (disputeId) return pathsFor.dispute(disputeId); const orderId = action === undefined ? id('orderId') : null; return orderId ? pathsFor.order(orderId) : null; }
    default: {
      const postId = id('postId'); if (postId) return pathsFor.post(postId);
      const productId = id('productId'); if (productId) return pathsFor.product(productId);
      const storyId = id('storyId'); if (storyId) return pathsFor.story(storyId);
      const highlightId = id('highlightId'); if (highlightId) return pathsFor.highlights(highlightId);
      const orderId = id('orderId'); if (orderId) return pathsFor.order(orderId);
      const conversationId = id('conversationId'); if (conversationId) return pathsFor.conversation(conversationId);
      const userId = id('userId', 'senderId'); return userId ? pathsFor.person(userId) : null;
    }
  }
}
