import type { Page, Route } from '@playwright/test';
import { createHash } from 'node:crypto';

const productId = 'web-fixture-camera';
const userIds = ['10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002'] as const;
const accessToken = `eyJhbGciOiJub25lIn0.${Buffer.from(JSON.stringify({ sub: userIds[0], exp: 4102444800 })).toString('base64url')}.x`;
export type BrowserFixture = {
  calls: Array<{ method: string; path: string; body?: unknown; hasBearer: boolean; cookiePresent: boolean; hasStepUp: boolean; hasViewOnceOpening: boolean; stepUpPurpose?: string }>;
  consumeCount: number;
  userId: string;
  profile: { id: string; displayName: string; username: string | null; avatarUrl: null; city?: string; deletionRequestedAt?: string | null };
  favorites: Set<string>;
  cartQuantity: number;
  comments: string[];
  savedPost: boolean;
  messages: Array<{ id: string; conversationId: string; senderId: string; content: string | null; type: string; createdAt: string; attachmentUrl?: string; viewOnce?: boolean }>;
  viewOnceFetches: number;
  viewOnceOpens: number;
  viewOnceCloses: number;
  viewOnceOpeningHash: string | null;
  viewOnceHeaderHashes: string[];
  viewOnceClosed: boolean;
  viewOnceFailNextMedia: boolean;
  muted: boolean;
  locationMessages: unknown[];
  productConversationStarts: number;
  notificationsRead: boolean;
  deletionStatus: number | null;
  closeFriendIds: Set<string>;
  starredIds: Set<string>;
  orderStatus: 'PENDING' | null;
  checkoutAmount: number | null;
  isArchived: boolean;
  reactionCount: number;
  viewedStories: Set<string>;
};

export function newBrowserFixture(): BrowserFixture {
  return {
    calls: [], consumeCount: 0, userId: userIds[0],
    profile: { id: userIds[0], displayName: 'Synthetic Buyer', username: null, avatarUrl: null },
    favorites: new Set(), cartQuantity: 0, comments: [], savedPost: false,
    messages: [
      { id: '30000000-0000-4000-8000-000000000003', conversationId: '40000000-0000-4000-8000-000000000004', senderId: userIds[1], content: 'Incoming synthetic note', type: 'TEXT', createdAt: '2026-10-07T10:00:00.000Z' },
      { id: '30000000-0000-4000-8000-000000000013', conversationId: '40000000-0000-4000-8000-000000000004', senderId: userIds[1], content: null, type: 'IMAGE', attachmentUrl: '/media/view-once/synthetic', viewOnce: true, createdAt: '2026-10-07T10:00:30.000Z' },
    ],
    viewOnceFetches: 0, viewOnceOpens: 0, viewOnceCloses: 0, viewOnceOpeningHash: null, viewOnceHeaderHashes: [], viewOnceClosed: false, viewOnceFailNextMedia: false, muted: false, locationMessages: [], productConversationStarts: 0, notificationsRead: false, deletionStatus: null, closeFriendIds: new Set([userIds[1]]), starredIds: new Set(), orderStatus: null, checkoutAmount: null, isArchived: false, reactionCount: 0, viewedStories: new Set(),
  };
}

const product = {
  id: productId, title: 'Câmera analógica', description: 'Câmera em ótimo estado, testada e pronta para uso.',
  price: 10000, condition: 'USED', categoryId: 'photo', sellerId: userIds[1], status: 'ACTIVE',
  quantity: 3, soldCount: 0, createdAt: '2026-10-01T12:00:00.000Z',
  seller: { id: userIds[1], displayName: 'Pessoa de teste', isVerified: true, city: 'São Paulo', state: 'SP' },
  images: [{ id: 'image-fixture', url: 'https://images.example.invalid/camera.jpg', order: 0 }],
};
const envelope = (data: unknown) => ({ data });
const send = (route: Route, data: unknown, status = 200) => route.fulfill({ status, contentType: 'application/json', body: JSON.stringify(envelope(data)) });

export async function installBrowserFixture(page: Page, state = newBrowserFixture()) {
  await page.context().addCookies([{ name: 'freebay_web_refresh', value: 'synthetic-refresh-cookie', url: 'http://127.0.0.1:5173', httpOnly: true, sameSite: 'Lax' }]);
  await page.route('**/*', async (route) => {
    const request = route.request(); const url = new URL(request.url());
    if (url.hostname === 'checkout.stripe.com') return route.fulfill({ status: 200, contentType: 'text/html', body: '<main>Synthetic hosted checkout fixture; no payment was attempted.</main>' });
    if (url.origin !== 'http://127.0.0.1:5173') return route.abort();
    const path = url.pathname; const method = request.method();
    if (!path.startsWith('/auth/') && !path.startsWith('/users') && !path.startsWith('/products') && !path.startsWith('/categories') && !path.startsWith('/favorites') && !path.startsWith('/cart') && !path.startsWith('/social') && !path.startsWith('/stories') && !path.startsWith('/chat') && !path.startsWith('/notifications') && !path.startsWith('/media')) return route.continue();
    let body: unknown;
    if (request.postData()) { try { body = request.postDataJSON(); } catch { body = '[multipart]'; } }
    const safeBody = body && typeof body === 'object' ? Object.fromEntries(Object.entries(body).map(([key, value]) => [key, ['password', 'token', 'proof', 'openingKey'].includes(key) ? '[redacted]' : value])) : body;
    const stepUpBody = body && typeof body === 'object' && 'purpose' in body && typeof body.purpose === 'string' ? body.purpose : undefined;
    state.calls.push({ method, path: `${path}${url.search}`, ...(safeBody === undefined ? {} : { body: safeBody }), hasBearer: Boolean(request.headers().authorization), cookiePresent: Boolean(request.headers().cookie?.includes('freebay_web_refresh=')), hasStepUp: Boolean(request.headers()['x-step-up-token']), hasViewOnceOpening: Boolean(request.headers()['x-view-once-opening']), ...(stepUpBody ? { stepUpPurpose: stepUpBody } : {}) });
    if (path === '/auth/web/magic-link/request' && method === 'POST') return send(route, { accepted: true });
    if (path === '/auth/web/magic-link/consume' && method === 'POST') { state.consumeCount++; state.userId = userIds[0]; return send(route, { user: { username: state.profile.username } }); }
    if (path === '/auth/web/session/access-token' && method === 'POST') return send(route, { token: accessToken });
    if (path === '/auth/web/session/logout' && method === 'POST') { state.userId = ''; return send(route, { ok: true }); }
    if (path === '/auth/web/login' && method === 'POST') { state.userId = userIds[0]; return send(route, { user: { username: state.profile.username } }); }
    if (path === '/users/me' && method === 'GET') return state.userId ? send(route, { ...state.profile, id: state.userId }) : send(route, { message: 'Unauthorized' }, 401);
    if (path === '/users/me/stats' && method === 'GET') return send(route, { followersCount: 2, followingCount: 1, postsCount: 1, productsCount: 0 });
    if (path === '/auth/complete-profile' && method === 'POST') { const input = body as { username: string; displayName?: string; city?: string }; state.profile = { ...state.profile, username: input.username, displayName: input.displayName ?? state.profile.displayName, ...(input.city ? { city: input.city } : {}) }; return send(route, { user: state.profile }); }
    if (path === '/users/me' && method === 'PATCH') { state.profile = { ...state.profile, ...(body as Partial<BrowserFixture['profile']>) }; return send(route, state.profile); }
    if (path === '/auth/web/step-up' && method === 'POST') return request.headers().authorization ? send(route, { stepUpToken: 'synthetic-step-up-token' }) : send(route, { message: 'Unauthorized' }, 401);
    if (path === '/users/me/export' && method === 'GET') return request.headers()['x-step-up-token'] === 'synthetic-step-up-token' ? send(route, { scope: ['profile'], excluded: ['credentials'] }) : send(route, { message: 'Step-up required' }, 403);
    if (path === '/users/me/web' && method === 'DELETE') { if (request.headers()['x-step-up-token'] !== 'synthetic-step-up-token') return send(route, { message: 'Step-up required' }, 403); state.deletionStatus = 409; return send(route, { message: 'Account has open orders, disputes or a wallet balance' }, 409); }
    if (path === '/users/me/web/deletion/cancel' && method === 'PATCH') { state.profile.deletionRequestedAt = null; return send(route, { cancelled: true }); }
    if (path === '/users/me/close-friends' && method === 'GET') return send(route, { users: state.closeFriendIds.size ? [{ id: userIds[1], displayName: 'Synthetic Friend', username: 'friend', avatarUrl: null }] : [] });
    if (path === '/users/me/close-friends/candidates' && method === 'GET') return send(route, { users: [{ id: userIds[1], displayName: 'Synthetic Friend', username: 'friend', avatarUrl: null }] });
    if (path === `/users/me/close-friends/${userIds[1]}/remove` && method === 'PATCH') { state.closeFriendIds.delete(userIds[1]); return send(route, { ok: true }); }
    if (path === `/users/me/close-friends/${userIds[1]}` && method === 'POST') { state.closeFriendIds.add(userIds[1]); return send(route, { ok: true }); }
    if (path === `/users/${userIds[1]}` && method === 'GET') return send(route, { reputationScore: 4.8, totalReviews: 6 });
    if (path === `/reviews/users/${userIds[1]}` && method === 'GET') return send(route, { reviews: [], total: 0, offset: 0, limit: 5 });
    if (path === '/products' && method === 'GET') return send(route, { products: [product], nextCursor: null });
    if (path === `/products/${productId}` && method === 'GET') return send(route, { product });
    if (path === '/categories' && method === 'GET') return send(route, { categories: [{ id: 'photo', name: 'Fotografia', parentId: null, children: [] }] });
    if (path === `/favorites/check/${productId}` && method === 'GET') return send(route, { isFavorited: state.favorites.has(productId) });
    if (path === `/favorites/${productId}` && method === 'POST') { if (state.favorites.has(productId)) state.favorites.delete(productId); else state.favorites.add(productId); return send(route, { isFavorited: state.favorites.has(productId) }); }
    if (path === `/cart/${productId}` && method === 'POST') { const input = body as { quantity: number }; state.cartQuantity = Math.min(3, input.quantity); return send(route, { item: { id: 'cart-row-fixture', quantity: state.cartQuantity } }); }
    if (path === '/cart' && method === 'GET') return send(route, { items: state.cartQuantity ? [{ id: 'cart-row-fixture', productId, quantity: state.cartQuantity, subtotal: 10000 * state.cartQuantity, product: { id: productId, title: product.title, price: 10000, sellerId: product.sellerId, images: [], seller: { id: product.sellerId, displayName: 'Pessoa de teste', avatarUrl: null, isVerified: true } } }] : [], totalItems: state.cartQuantity, totalPrice: 10000 * state.cartQuantity });
    if (path === '/cart/checkout/recovery' && method === 'GET') return send(route, null);
    if (path === '/cart/checkout' && method === 'POST') { state.orderStatus = 'PENDING'; state.checkoutAmount = 12500; return send(route, { paymentGroupId: '50000000-0000-4000-8000-000000000005', items: [{ orderId: '60000000-0000-4000-8000-000000000006', productId, productTitle: product.title, quantity: state.cartQuantity, amount: 12500 }], totalOrders: 1, totalAmount: state.checkoutAmount, checkoutUrl: 'https://checkout.stripe.com/c/pay/synthetic', expiresAt: null }); }
    if (path === '/orders/my/purchases' && method === 'GET') return send(route, { items: state.orderStatus ? [{ id: '60000000-0000-4000-8000-000000000006', buyerId: state.userId, sellerId: userIds[1], productId, paymentGroupId: '50000000-0000-4000-8000-000000000005', amount: 12500, platformFee: 0, sellerAmount: 12500, status: state.orderStatus, escrowStatus: 'PENDING', createdAt: '2026-10-07T10:00:00.000Z', product: { title: product.title } }] : [], hasMore: false, nextCursor: null });
    if (path === '/social/feed' && method === 'GET') return send(route, { posts: [{ id: '70000000-0000-4000-8000-000000000007', userId: userIds[1], content: 'Public fixture post', imageUrl: null, audience: 'EVERYONE', type: 'REGULAR', createdAt: '2026-10-07T09:00:00.000Z', user: { id: userIds[1], displayName: 'Public Author', username: 'author' }, likesCount: 0, commentsCount: state.comments.length, sharesCount: 0, isLiked: false, isSaved: state.savedPost, hasReposted: false, hasMore: false, nextCursor: null }], hasMore: false, nextCursor: null });
    if (path === '/social/posts/70000000-0000-4000-8000-000000000007' && method === 'GET') return send(route, { id: '70000000-0000-4000-8000-000000000007', userId: userIds[1], content: 'Public fixture post', audience: 'EVERYONE', type: 'REGULAR', createdAt: '2026-10-07T09:00:00.000Z', user: { id: userIds[1], displayName: 'Public Author', username: 'author' }, likesCount: 0, commentsCount: state.comments.length, isLiked: false, isSaved: state.savedPost });
    if (path.includes('/comments') && method === 'GET') return send(route, state.comments.map((content, index) => ({ id: `comment-${index}`, postId: '70000000-0000-4000-8000-000000000007', userId: state.userId, content, createdAt: '2026-10-07T09:05:00.000Z', likesCount: 0, isLiked: false, user: { id: state.userId, displayName: state.profile.displayName }, replies: [] })));
    if (path.includes('/comments') && method === 'POST') { const input = body as { content: string }; state.comments.push(input.content); return send(route, { id: `comment-${state.comments.length}`, postId: '70000000-0000-4000-8000-000000000007', userId: state.userId, content: input.content, createdAt: '2026-10-07T09:05:00.000Z', likesCount: 0, isLiked: false, replies: [] }); }
    if (path === '/social/posts/70000000-0000-4000-8000-000000000007/save' && method === 'POST') { state.savedPost = true; return send(route, { active: true }); }
    if (path === '/social/posts/70000000-0000-4000-8000-000000000007/unsave' && method === 'PATCH') { state.savedPost = false; return send(route, { active: false }); }
    if (path === '/stories/user/20000000-0000-4000-8000-000000000002' && method === 'GET') return send(route, [1, 2].map((number) => ({ id: `story-fixture-${number}`, userId: '20000000-0000-4000-8000-000000000002', imageUrl: `/media/story/story-fixture-${number}.png`, mediaType: 'IMAGE', audience: 'EVERYONE', caption: `Story ${number} loaded`, textBlocks: [], createdAt: '2026-10-07T10:00:0${number}.000Z', expiresAt: '2026-10-08T10:00:00.000Z', user: { id: '20000000-0000-4000-8000-000000000002', displayName: 'Synthetic Story Author', avatarUrl: null } })));
    if (path.startsWith('/stories/story-fixture-') && path.endsWith('/view') && method === 'POST') { state.viewedStories.add(path.split('/')[2]); return send(route, { viewed: true }); }
    if (path === '/chat/conversations' && method === 'POST') { state.productConversationStarts++; return send(route, { conversationId: '40000000-0000-4000-8000-000000000004', status: 'ACCEPTED' }); }
    if (path === '/chat/conversations' && method === 'GET') { const otherUser = { id: userIds[1], displayName: state.productConversationStarts ? 'Pessoa de teste' : 'Synthetic Sender' }; return send(route, { items: [{ id: '40000000-0000-4000-8000-000000000004', otherUser, threadType: 'DIRECT', status: 'ACCEPTED', lastMessage: state.messages.at(-1), ...(state.productConversationStarts ? { product: { id: productId, title: product.title } } : {}) }, { id: '40000000-0000-4000-8000-000000000008', otherUser: { id: userIds[1], displayName: 'Synthetic Forward Target' }, threadType: 'DIRECT', status: 'ACCEPTED', lastMessage: null }], nextCursor: null }); }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004' && method === 'GET') { const otherUser = { id: userIds[1], displayName: state.productConversationStarts ? 'Pessoa de teste' : 'Synthetic Sender' }; const messages = state.messages.map((message) => ({ attachmentUrl: null, metadata: null, replyToId: null, replyTo: null, deletedAt: null, readAt: null, deliveredAt: null, viewOnce: false, ...message })); return send(route, { messages, hasMore: false, nextCursor: null, threadType: 'DIRECT', otherUserId: otherUser.id, otherUser: { ...otherUser, avatarUrl: null }, preference: { isArchived: state.isArchived, theme: 'DEFAULT', backgroundUrl: null, muted: state.muted } }); }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004/messages/30000000-0000-4000-8000-000000000013/view-once/open' && method === 'POST') {
      state.viewOnceOpens++;
      const openingKey = body && typeof body === 'object' && 'openingKey' in body && typeof body.openingKey === 'string' ? body.openingKey : '';
      if (!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(openingKey)) return send(route, { message: 'Not found' }, 404);
      const hash = createHash('sha256').update(openingKey).digest('hex');
      if (state.viewOnceClosed || (state.viewOnceOpeningHash && state.viewOnceOpeningHash !== hash)) return send(route, { message: 'Not found' }, 404);
      state.viewOnceOpeningHash = hash;
      return send(route, { messageId: '30000000-0000-4000-8000-000000000013', readAt: '2026-10-07T10:01:00.000Z', mediaUrl: '/media/view-once/synthetic' });
    }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004/messages/30000000-0000-4000-8000-000000000013/view-once/close' && method === 'POST') {
      const openingKey = body && typeof body === 'object' && 'openingKey' in body && typeof body.openingKey === 'string' ? body.openingKey : '';
      if (!state.viewOnceOpeningHash || state.viewOnceOpeningHash !== createHash('sha256').update(openingKey).digest('hex')) return send(route, { message: 'Not found' }, 404);
      state.viewOnceClosed = true; state.viewOnceCloses++; return send(route, { ok: true });
    }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004/messages' && method === 'POST') { const input = body as { content?: string; type?: string; clientMessageId: string; replyToId?: string; metadata?: unknown }; const item = { id: `80000000-0000-4000-8000-${String(state.messages.length).padStart(12, '0')}`, conversationId: '40000000-0000-4000-8000-000000000004', senderId: state.userId, content: input.content ?? null, type: input.type ?? 'TEXT', createdAt: '2026-10-07T10:01:00.000Z', ...(input.replyToId ? { replyToId: input.replyToId } : {}), ...(input.metadata ? { metadata: input.metadata } : {}) }; if (input.type === 'LOCATION') state.locationMessages.push(item); state.messages.push(item); return send(route, item); }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004/read' && method === 'PATCH') return send(route, { ok: true });
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004/theme' && method === 'PATCH') { if (typeof (body as { muted?: unknown }).muted === 'boolean') state.muted = (body as { muted: boolean }).muted; return send(route, { isArchived: state.isArchived, theme: 'DEFAULT', backgroundUrl: null, muted: state.muted }); }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004/starred' && method === 'GET') return send(route, state.messages.filter((item) => state.starredIds.has(item.id)));
    if (path === '/chat/messages/forward' && method === 'POST') return send(route, { forwardedCount: (body as { messageIds: string[] }).messageIds.length, messages: [] });
    if (path.endsWith('/30000000-0000-4000-8000-000000000003/react') && method === 'POST') { state.reactionCount = 1; return send(route, { reactions: [{ emoji: (body as { emoji: string }).emoji, count: state.reactionCount, reactedByMe: true }] }); }
    if (path.endsWith('/30000000-0000-4000-8000-000000000003/star') && method === 'POST') { state.starredIds.add('30000000-0000-4000-8000-000000000003'); return send(route, { starred: true }); }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004/archive' && method === 'PATCH') { state.isArchived = Boolean((body as { archived: boolean }).archived); return send(route, { ok: true }); }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004/messages' && url.searchParams.get('type') === 'IMAGE') return send(route, { messages: [], nextCursor: null });
    if (path === '/notifications' && method === 'GET') return send(route, { items: [{ id: '90000000-0000-4000-8000-000000000009', content: 'Synthetic notification', read: false, createdAt: '2026-10-07T08:00:00.000Z' }], nextCursor: null, hasMore: false });
    if (path === '/notifications/read-all' && method === 'POST') { state.notificationsRead = true; return send(route, { ok: true }); }
    if (path.startsWith('/media/story/')) return route.fulfill({ status: 200, contentType: 'image/png', body: Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=', 'base64') });
    if (path.startsWith('/media/')) { state.viewOnceFetches++; const key = request.headers()['x-view-once-opening']; const hash = key ? createHash('sha256').update(key).digest('hex') : ''; state.viewOnceHeaderHashes.push(hash); if (!key || state.viewOnceClosed || !state.viewOnceOpeningHash || state.viewOnceOpeningHash !== hash) return route.fulfill({ status: 403, contentType: 'application/json', body: JSON.stringify({ message: 'Opening required' }) }); if (state.viewOnceFailNextMedia) { state.viewOnceFailNextMedia = false; return route.fulfill({ status: 503, contentType: 'application/json', body: JSON.stringify({ message: 'Retry this same opening' }) }); } return route.fulfill({ status: 200, contentType: 'image/png', body: Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=', 'base64') }); }
    return route.fulfill({ status: 404, contentType: 'application/json', body: JSON.stringify({ message: `Fixture route missing: ${method} ${path}` }) });
  });
  return state;
}

export { productId, userIds };
