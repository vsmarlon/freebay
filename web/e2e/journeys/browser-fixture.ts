import { expect, type Page, type Route } from '@playwright/test';
import { createHash } from 'node:crypto';

const productId = 'web-fixture-camera';
const userIds = [
  '10000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000002',
] as const;
const accessToken = `eyJhbGciOiJub25lIn0.${Buffer.from(JSON.stringify({ sub: userIds[0], exp: 4102444800 })).toString('base64url')}.x`;
export type BrowserFixture = {
  calls: Array<{
    method: string;
    path: string;
    body?: unknown;
    hasBearer: boolean;
    cookiePresent: boolean;
    hasStepUp: boolean;
    hasViewOnceOpening: boolean;
    stepUpPurpose?: string;
  }>;
  consumeCount: number;
  userId: string;
  role: 'USER' | 'ADMIN';
  profile: {
    id: string;
    displayName: string;
    username: string | null;
    avatarUrl: null;
    city?: string;
    deletionRequestedAt?: string | null;
  };
  favorites: Set<string>;
  cartQuantity: number;
  comments: string[];
  savedPost: boolean;
  likedPost: boolean;
  repostedPost: boolean;
  likedComment: boolean;
  messages: Array<{
    id: string;
    conversationId: string;
    senderId: string;
    content: string | null;
    type: string;
    createdAt: string;
    attachmentUrl?: string;
    viewOnce?: boolean;
  }>;
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
  orderStatus:
    | 'PENDING'
    | 'CONFIRMED'
    | 'SHIPPED'
    | 'DELIVERED'
    | 'DISPUTED'
    | 'COMPLETED'
    | 'CANCELLED'
    | null;
  orderEscrow: 'HELD' | 'RELEASED' | 'REFUNDED';
  dispute: {
    id: string;
    status: 'OPEN' | 'AWAITING_SELLER' | 'AWAITING_BUYER' | 'ESCALATED' | 'RESOLVED' | 'CANCELLED';
    reason: string;
    buyerEvidence: string | null;
  } | null;
  checkoutAmount: number | null;
  isArchived: boolean;
  reactionCount: number;
  viewedStories: Set<string>;
};

export function newBrowserFixture(): BrowserFixture {
  return {
    calls: [],
    consumeCount: 0,
    userId: userIds[0],
    role: 'USER',
    profile: { id: userIds[0], displayName: 'Synthetic Buyer', username: null, avatarUrl: null },
    favorites: new Set(),
    cartQuantity: 0,
    comments: [],
    savedPost: false,
    likedPost: false,
    repostedPost: false,
    likedComment: false,
    messages: [
      {
        id: '30000000-0000-4000-8000-000000000003',
        conversationId: '40000000-0000-4000-8000-000000000004',
        senderId: userIds[1],
        content: 'Incoming synthetic note',
        type: 'TEXT',
        createdAt: '2026-10-07T10:00:00.000Z',
      },
      {
        id: '30000000-0000-4000-8000-000000000013',
        conversationId: '40000000-0000-4000-8000-000000000004',
        senderId: userIds[1],
        content: null,
        type: 'IMAGE',
        attachmentUrl: '/media/view-once/synthetic',
        viewOnce: true,
        createdAt: '2026-10-07T10:00:30.000Z',
      },
    ],
    viewOnceFetches: 0,
    viewOnceOpens: 0,
    viewOnceCloses: 0,
    viewOnceOpeningHash: null,
    viewOnceHeaderHashes: [],
    viewOnceClosed: false,
    viewOnceFailNextMedia: false,
    muted: false,
    locationMessages: [],
    productConversationStarts: 0,
    notificationsRead: false,
    deletionStatus: null,
    closeFriendIds: new Set([userIds[1]]),
    starredIds: new Set(),
    orderStatus: null,
    orderEscrow: 'HELD',
    dispute: null,
    checkoutAmount: null,
    isArchived: false,
    reactionCount: 0,
    viewedStories: new Set(),
  };
}

const product = {
  id: productId,
  title: 'Câmera analógica',
  description: 'Câmera em ótimo estado, testada e pronta para uso.',
  price: 10000,
  condition: 'USED',
  categoryId: 'photo',
  sellerId: userIds[1],
  status: 'ACTIVE',
  quantity: 3,
  soldCount: 0,
  createdAt: '2026-10-01T12:00:00.000Z',
  seller: {
    id: userIds[1],
    displayName: 'Pessoa de teste',
    isVerified: true,
    city: 'São Paulo',
    state: 'SP',
  },
  images: [{ id: 'image-fixture', url: 'https://images.example.invalid/camera.jpg', order: 0 }],
};
const orderId = '60000000-0000-4000-8000-000000000006';
const paymentGroupId = '50000000-0000-4000-8000-000000000005';
const disputeId = 'a0000000-0000-4000-8000-00000000000a';
type DisputeState = NonNullable<BrowserFixture['dispute']>;

// Mirrors backend availableOrderActions for the synthetic buyer
// (orders/domain/order-state.ts): a PAID transaction with a captured charge and
// HELD escrow decides cancel/confirm/dispute eligibility; PENDING with an
// in-flight payment group offers nothing.
function buyerAllowedActions(state: BrowserFixture): string[] {
  if (state.orderStatus === 'CONFIRMED') return ['CANCEL', 'CONFIRM_DELIVERY', 'OPEN_DISPUTE'];
  if (state.orderStatus === 'SHIPPED') return ['CONFIRM_DELIVERY', 'OPEN_DISPUTE'];
  if (state.orderStatus === 'DELIVERED')
    return ['CONFIRM_DELIVERY', state.dispute ? 'REOPEN_DISPUTE' : 'OPEN_DISPUTE'];
  if (state.orderStatus === 'DISPUTED') return ['VIEW_DISPUTE'];
  return [];
}

function orderView(state: BrowserFixture) {
  return {
    id: orderId,
    buyerId: state.userId,
    sellerId: userIds[1],
    productId,
    amount: 12500,
    platformFee: 0,
    sellerAmount: 12500,
    status: state.orderStatus,
    escrowStatus: state.orderEscrow,
    createdAt: '2026-10-07T10:00:00.000Z',
    product: { title: product.title },
    buyer: { id: state.userId, displayName: state.profile.displayName, avatarUrl: null },
    seller: { id: userIds[1], displayName: product.seller.displayName, avatarUrl: null },
    transaction: {
      status: state.orderStatus === 'PENDING' ? 'PENDING' : 'PAID',
      paymentGroupId,
      chargeId: state.orderStatus === 'PENDING' ? null : 'ch_fixture_order',
      externalId: null,
    },
    dispute: state.dispute ? { id: state.dispute.id, status: state.dispute.status } : null,
  };
}

function disputeView(state: BrowserFixture, dispute: DisputeState) {
  return {
    id: dispute.id,
    orderId,
    openedById: state.userId,
    reason: dispute.reason,
    status: dispute.status,
    resolution: null,
    buyerEvidence: dispute.buyerEvidence,
    sellerEvidence: null,
    createdAt: '2026-10-07T11:00:00.000Z',
    expiresAt: '2026-10-10T11:00:00.000Z',
    resolvedAt: null,
    order: {
      buyerId: state.userId,
      sellerId: userIds[1],
      buyer: { displayName: state.profile.displayName },
      seller: { displayName: product.seller.displayName },
      product: { title: product.title },
    },
  };
}

const envelope = (data: unknown) => ({ data });
const send = (route: Route, data: unknown, status = 200) =>
  route.fulfill({ status, contentType: 'application/json', body: JSON.stringify(envelope(data)) });

// Base URL of the app under test. Defaults to 5173; override with E2E_BASE_URL to run the suite against another instance (e.g. 5174) alongside a dev server.
const baseUrl = process.env.E2E_BASE_URL ?? 'http://127.0.0.1:5173';
const baseOrigin = new URL(baseUrl).origin;
export async function installBrowserFixture(page: Page, state = newBrowserFixture()) {
  await page.addInitScript(() => {
    if (sessionStorage.getItem('freebay.fixture.initialized') === 'true') return;
    sessionStorage.setItem('freebay.fixture.initialized', 'true');
    for (const key of Object.keys(localStorage)) {
      if (key.startsWith('freebay.welcome.seen.')) localStorage.removeItem(key);
    }
  });
  await page.context().addCookies([
    {
      name: 'freebay_web_refresh',
      value: 'synthetic-refresh-cookie',
      url: baseUrl,
      httpOnly: true,
      sameSite: 'Lax',
    },
  ]);
  await page.route('**/*', async (route) => {
    const request = route.request();
    const url = new URL(request.url());
    if (url.hostname === 'checkout.stripe.com')
      return route.fulfill({
        status: 200,
        contentType: 'text/html',
        body: '<main>Synthetic hosted checkout fixture; no payment was attempted.</main>',
      });
    if (url.origin !== baseOrigin) return route.abort();
    const path = url.pathname;
    const method = request.method();
    if (
      !path.startsWith('/auth/') &&
      !path.startsWith('/users') &&
      !path.startsWith('/products') &&
      !path.startsWith('/categories') &&
      !path.startsWith('/favorites') &&
      !path.startsWith('/cart') &&
      !path.startsWith('/orders') &&
      !path.startsWith('/reviews') &&
      !path.startsWith('/payments') &&
      !path.startsWith('/wallet') &&
      !path.startsWith('/disputes') &&
      !path.startsWith('/admin') &&
      !path.startsWith('/social') &&
      !path.startsWith('/stories') &&
      !path.startsWith('/chat') &&
      !path.startsWith('/notifications') &&
      !path.startsWith('/media') &&
      path !== '/reports'
    )
      return route.continue();
    let body: { targetUserId?: string; productId?: string } | unknown;
    if (request.postData()) {
      try {
        body = request.postDataJSON();
      } catch {
        body = '[multipart]';
      }
    }
    const safeBody =
      body && typeof body === 'object'
        ? Object.fromEntries(
            Object.entries(body).map(([key, value]) => [
              key,
              ['password', 'token', 'proof', 'openingKey'].includes(key) ? '[redacted]' : value,
            ]),
          )
        : body;
    const stepUpBody =
      body && typeof body === 'object' && 'purpose' in body && typeof body.purpose === 'string'
        ? body.purpose
        : undefined;
    state.calls.push({
      method,
      path: `${path}${url.search}`,
      ...(safeBody === undefined ? {} : { body: safeBody }),
      hasBearer: Boolean(request.headers().authorization),
      cookiePresent: Boolean(request.headers().cookie?.includes('freebay_web_refresh=')),
      hasStepUp: Boolean(request.headers()['x-step-up-token']),
      hasViewOnceOpening: Boolean(request.headers()['x-view-once-opening']),
      ...(stepUpBody ? { stepUpPurpose: stepUpBody } : {}),
    });
    if (path === '/auth/web/magic-link/request' && method === 'POST')
      return send(route, { accepted: true });
    if (path === '/auth/web/magic-link/consume' && method === 'POST') {
      state.consumeCount++;
      state.userId = userIds[0];
      return send(route, { user: { username: state.profile.username } });
    }
    if (path === '/auth/web/session/access-token' && method === 'POST')
      return send(route, { token: accessToken });
    if (path === '/auth/web/session/logout' && method === 'POST') {
      state.userId = '';
      return send(route, { ok: true });
    }
    if (path === '/auth/web/login' && method === 'POST') {
      state.userId = userIds[0];
      return send(route, { user: { username: state.profile.username } });
    }
    if (path === '/users/me' && method === 'GET')
      return state.userId
        ? send(route, { ...state.profile, id: state.userId, role: state.role })
        : send(route, { message: 'Unauthorized' }, 401);
    if (path === '/users/me/stats' && method === 'GET')
      return send(route, { followersCount: 2, followingCount: 1, postsCount: 1, productsCount: 0 });
    if (path === '/auth/complete-profile' && method === 'POST') {
      const input = body as { username: string; displayName?: string; city?: string };
      state.profile = {
        ...state.profile,
        username: input.username,
        displayName: input.displayName ?? state.profile.displayName,
        ...(input.city ? { city: input.city } : {}),
      };
      return send(route, { user: state.profile });
    }
    if (path === '/users/me' && method === 'PATCH') {
      state.profile = { ...state.profile, ...(body as Partial<BrowserFixture['profile']>) };
      return send(route, state.profile);
    }
    if (path === '/auth/web/step-up' && method === 'POST')
      return request.headers().authorization
        ? send(route, { stepUpToken: 'synthetic-step-up-token' })
        : send(route, { message: 'Unauthorized' }, 401);
    if (path === '/users/me/export' && method === 'GET')
      return request.headers()['x-step-up-token'] === 'synthetic-step-up-token'
        ? send(route, { scope: ['profile'], excluded: ['credentials'] })
        : send(route, { message: 'Step-up required' }, 403);
    if (path === '/users/me/web' && method === 'DELETE') {
      if (request.headers()['x-step-up-token'] !== 'synthetic-step-up-token')
        return send(route, { message: 'Step-up required' }, 403);
      state.deletionStatus = 409;
      return send(route, { message: 'Account has open orders, disputes or a wallet balance' }, 409);
    }
    if (path === '/users/me/web/deletion/cancel' && method === 'PATCH') {
      state.profile.deletionRequestedAt = null;
      return send(route, { cancelled: true });
    }
    if (path === '/users/me/close-friends' && method === 'GET')
      return send(route, {
        users: state.closeFriendIds.size
          ? [
              {
                id: userIds[1],
                displayName: 'Synthetic Friend',
                username: 'friend',
                avatarUrl: null,
              },
            ]
          : [],
      });
    if (path === '/users/me/close-friends/candidates' && method === 'GET')
      return send(route, {
        users: [
          { id: userIds[1], displayName: 'Synthetic Friend', username: 'friend', avatarUrl: null },
        ],
      });
    if (path === `/users/me/close-friends/${userIds[1]}/remove` && method === 'PATCH') {
      state.closeFriendIds.delete(userIds[1]);
      return send(route, { ok: true });
    }
    if (path === `/users/me/close-friends/${userIds[1]}` && method === 'POST') {
      state.closeFriendIds.add(userIds[1]);
      return send(route, { ok: true });
    }
    if (path === `/users/${userIds[1]}` && method === 'GET')
      return send(route, { reputationScore: 4.8, totalReviews: 6 });
    if (path === `/reviews/users/${userIds[1]}` && method === 'GET')
      return send(route, { reviews: [], total: 0, offset: 0, limit: 5 });
    if (path === '/products' && method === 'GET')
      return send(route, { products: [product], nextCursor: null });
    if (path === `/products/${productId}` && method === 'GET') return send(route, { product });
    if (path === '/categories' && method === 'GET')
      return send(route, {
        categories: [{ id: 'photo', name: 'Fotografia', parentId: null, children: [] }],
      });
    if (path === `/favorites/check/${productId}` && method === 'GET')
      return send(route, { isFavorited: state.favorites.has(productId) });
    if (path === `/favorites/${productId}` && method === 'POST') {
      if (state.favorites.has(productId)) state.favorites.delete(productId);
      else state.favorites.add(productId);
      return send(route, { isFavorited: state.favorites.has(productId) });
    }
    if (path === `/cart/${productId}` && method === 'POST') {
      const input = body as { quantity: number };
      state.cartQuantity = Math.min(3, input.quantity);
      return send(route, { item: { id: 'cart-row-fixture', quantity: state.cartQuantity } });
    }
    if (path === '/cart' && method === 'GET')
      return send(route, {
        items: state.cartQuantity
          ? [
              {
                id: 'cart-row-fixture',
                productId,
                quantity: state.cartQuantity,
                subtotal: 10000 * state.cartQuantity,
                product: {
                  id: productId,
                  title: product.title,
                  price: 10000,
                  sellerId: product.sellerId,
                  images: [],
                  seller: {
                    id: product.sellerId,
                    displayName: 'Pessoa de teste',
                    avatarUrl: null,
                    isVerified: true,
                  },
                },
              },
            ]
          : [],
        totalItems: state.cartQuantity,
        totalPrice: 10000 * state.cartQuantity,
      });
    if (path === '/cart/checkout/recovery' && method === 'GET') return send(route, null);
    if (path === '/cart/checkout' && method === 'POST') {
      state.orderStatus = 'PENDING';
      state.orderEscrow = 'HELD';
      state.checkoutAmount = 12500;
      return send(route, {
        paymentGroupId,
        items: [
          {
            orderId,
            productId,
            productTitle: product.title,
            quantity: state.cartQuantity,
            amount: 12500,
          },
        ],
        totalOrders: 1,
        totalAmount: state.checkoutAmount,
        checkoutUrl: 'https://checkout.stripe.com/c/pay/synthetic',
        expiresAt: null,
      });
    }
    if (path === '/orders/my/purchases' && method === 'GET')
      return send(route, {
        items: state.orderStatus ? [orderView(state)] : [],
        hasMore: false,
        nextCursor: null,
      });
    if (path === '/orders/my/sales' && method === 'GET')
      return send(route, { items: [], hasMore: false, nextCursor: null });
    if (path === `/orders/${orderId}` && method === 'GET') {
      if (!state.orderStatus) return send(route, { message: 'Not found' }, 404);
      return send(route, { order: orderView(state), allowedActions: buyerAllowedActions(state) });
    }
    if (path === `/orders/${orderId}/ship` && method === 'PATCH') {
      state.orderStatus = 'SHIPPED';
      return send(route, { order: orderView(state) });
    }
    if (path === `/orders/${orderId}/deliver` && method === 'PATCH') {
      state.orderStatus = 'DELIVERED';
      return send(route, { order: orderView(state) });
    }
    if (path === `/orders/${orderId}/confirm` && method === 'PATCH') {
      state.orderStatus = 'COMPLETED';
      state.orderEscrow = 'RELEASED';
      return send(route, { order: orderView(state) });
    }
    if (path === `/orders/${orderId}/cancel` && method === 'PATCH') {
      state.orderStatus = 'CANCELLED';
      return send(route, { order: orderView(state) });
    }
    if (path === `/payments/checkout/${orderId}` && method === 'POST')
      return send(route, { checkoutUrl: 'https://checkout.stripe.com/c/pay/synthetic' });
    if (path === '/disputes' && method === 'POST') {
      const input = body as { orderId: string; reason: string };
      if (state.dispute) {
        state.dispute.status = 'OPEN';
        state.dispute.reason = input.reason;
      } else
        state.dispute = {
          id: disputeId,
          status: 'OPEN',
          reason: input.reason,
          buyerEvidence: null,
        };
      state.orderStatus = 'DISPUTED';
      return send(route, { id: state.dispute.id });
    }
    if (path === '/disputes' && method === 'GET')
      return send(route, { disputes: state.dispute ? [disputeView(state, state.dispute)] : [] });
    if (path === `/disputes/${disputeId}` && method === 'GET') {
      if (!state.dispute) return send(route, { message: 'Not found' }, 404);
      return send(route, { dispute: disputeView(state, state.dispute) });
    }
    if (path === `/disputes/${disputeId}/evidence` && method === 'POST') {
      const input = body as { evidence: string };
      if (state.dispute) {
        state.dispute.status = 'AWAITING_SELLER';
        state.dispute.buyerEvidence = input.evidence;
      }
      return send(route, { ok: true });
    }
    if (path === `/disputes/${disputeId}/withdraw` && method === 'PATCH') {
      if (state.dispute) {
        state.dispute.status = 'CANCELLED';
        state.orderStatus = 'DELIVERED';
      }
      return send(route, { ok: true });
    }
    if (path === `/disputes/${disputeId}/resolve` && method === 'PATCH') {
      const input = body as { resolution: string; winner: 'BUYER' | 'SELLER' };
      if (state.dispute) {
        state.dispute.status = 'RESOLVED';
        if (input.winner === 'BUYER') {
          state.orderStatus = 'CANCELLED';
          state.orderEscrow = 'REFUNDED';
        } else {
          state.orderStatus = 'COMPLETED';
          state.orderEscrow = 'RELEASED';
        }
      }
      return send(route, { ok: true });
    }
    if (path === '/admin/disputes' && method === 'GET') {
      if (!state.dispute) return send(route, { disputes: [] });
      const status = url.searchParams.get('status');
      const matches = !status || status === 'ALL' || state.dispute.status === status;
      if (!matches) return send(route, { disputes: [] });
      return send(route, {
        disputes: [
          {
            ...disputeView(state, state.dispute),
            winner: null,
            resolution: null,
            order: {
              id: orderId,
              buyerId: state.userId,
              sellerId: userIds[1],
              amount: 12500,
              status: state.orderStatus ?? 'DISPUTED',
              buyer: { id: state.userId, displayName: state.profile.displayName },
              seller: { id: userIds[1], displayName: product.seller.displayName },
              product: { title: product.title, imageUrl: null },
            },
            openedBy: { id: state.userId, displayName: state.profile.displayName },
          },
        ],
      });
    }
    if (path === '/wallet' && method === 'GET')
      return send(route, { balance: 5000, pendingBalance: 0, availableBalance: 5000 });
    if (path === '/wallet/transactions' && method === 'GET')
      return send(route, { items: [], hasMore: false, nextCursor: null });
    if (path === '/payments/connect/status' && method === 'GET')
      return send(route, { status: 'transfer-ready', requirementsDue: [] });
    if (path === '/payments/connect/onboarding' && method === 'POST')
      return send(route, { onboardingUrl: 'https://connect.stripe.com/synthetic-onboarding' });
    if (path === '/payments/connect/dashboard' && method === 'POST')
      return send(route, { dashboardUrl: 'https://dashboard.stripe.com/synthetic' });
    if (path === `/reviews/orders/${orderId}/can-review` && method === 'GET')
      return send(route, { canReview: false, reason: 'ORDER_NOT_COMPLETED' });
    if (path === '/social/feed' && method === 'GET')
      return send(route, {
        posts: [
          {
            id: '70000000-0000-4000-8000-000000000007',
            userId: userIds[1],
            content: 'Public fixture post',
            media: [],
            imageUrl: null,
            audience: 'EVERYONE',
            type: 'REGULAR',
            createdAt: '2026-10-07T09:00:00.000Z',
            user: { id: userIds[1], displayName: 'Public Author', username: 'author' },
            likesCount: 0,
            commentsCount: state.comments.length,
            sharesCount: 0,
            isLiked: false,
            isSaved: state.savedPost,
            hasReposted: false,
            hasMore: false,
            nextCursor: null,
          },
        ],
        hasMore: false,
        nextCursor: null,
      });
    if (path === '/social/posts/70000000-0000-4000-8000-000000000007' && method === 'GET')
      return send(route, {
        id: '70000000-0000-4000-8000-000000000007',
        userId: userIds[1],
        content: 'Public fixture post',
        media: [],
        audience: 'EVERYONE',
        type: 'REGULAR',
        createdAt: '2026-10-07T09:00:00.000Z',
        user: { id: userIds[1], displayName: 'Public Author', username: 'author' },
        likesCount: 0,
        commentsCount: state.comments.length,
        isLiked: false,
        isSaved: state.savedPost,
      });
    if (path.includes('/comments') && method === 'GET')
      return send(
        route,
        state.comments.map((content, index) => ({
          id: `comment-${index}`,
          postId: '70000000-0000-4000-8000-000000000007',
          userId: state.userId,
          content,
          createdAt: '2026-10-07T09:05:00.000Z',
          likesCount: index === 0 ? (state.likedComment ? 1 : 0) : 0,
          isLiked: index === 0 && state.likedComment,
          user: { id: state.userId, displayName: state.profile.displayName },
          replies: [],
        })),
      );
    if (path.includes('/comments') && method === 'POST') {
      const input = body as { content: string };
      state.comments.push(input.content);
      return send(route, {
        id: `comment-${state.comments.length}`,
        postId: '70000000-0000-4000-8000-000000000007',
        userId: state.userId,
        content: input.content,
        createdAt: '2026-10-07T09:05:00.000Z',
        commentsCount: state.comments.length,
      });
    }
    if (path === '/social/posts/70000000-0000-4000-8000-000000000007/like' && method === 'POST') {
      state.likedPost = true;
      return send(route, { active: true, count: 1 });
    }
    if (
      path === '/social/posts/70000000-0000-4000-8000-000000000007/unlike' &&
      method === 'PATCH'
    ) {
      state.likedPost = false;
      return send(route, { active: false, count: 0 });
    }
    if (path === '/social/posts/70000000-0000-4000-8000-000000000007/share' && method === 'POST') {
      state.repostedPost = true;
      return send(route, { active: true, count: 1 });
    }
    if (
      path === '/social/posts/70000000-0000-4000-8000-000000000007/unshare' &&
      method === 'PATCH'
    ) {
      state.repostedPost = false;
      return send(route, { active: false, count: 0 });
    }
    if (path === '/social/comments/comment-0/like' && method === 'POST') {
      state.likedComment = true;
      return send(route, { active: true, count: 1 });
    }
    if (path === '/social/comments/comment-0/unlike' && method === 'PATCH') {
      state.likedComment = false;
      return send(route, { active: false, count: 0 });
    }
    if (path === '/social/posts/70000000-0000-4000-8000-000000000007/save' && method === 'POST') {
      state.savedPost = true;
      return send(route, { active: true });
    }
    if (
      path === '/social/posts/70000000-0000-4000-8000-000000000007/unsave' &&
      method === 'PATCH'
    ) {
      state.savedPost = false;
      return send(route, { active: false });
    }
    if (path === '/reports' && method === 'POST') return send(route, { accepted: true });
    if (path === '/stories/user/20000000-0000-4000-8000-000000000002' && method === 'GET')
      return send(
        route,
        [1, 2].map((number) => ({
          id: `story-fixture-${number}`,
          userId: '20000000-0000-4000-8000-000000000002',
          imageUrl: `/media/story/story-fixture-${number}.png`,
          mediaType: 'IMAGE',
          audience: 'EVERYONE',
          caption: `Story ${number} loaded`,
          textBlocks: [],
          createdAt: '2026-10-07T10:00:0${number}.000Z',
          expiresAt: '2026-10-08T10:00:00.000Z',
          user: {
            id: '20000000-0000-4000-8000-000000000002',
            displayName: 'Synthetic Story Author',
            avatarUrl: null,
          },
        })),
      );
    if (path.startsWith('/stories/story-fixture-') && path.endsWith('/view') && method === 'POST') {
      state.viewedStories.add(path.split('/')[2]);
      return send(route, { viewed: true });
    }
    if (path === '/chat/conversations' && method === 'POST') {
      state.productConversationStarts++;
      const seller =
        product &&
        body &&
        typeof body === 'object' &&
        (body as { productId?: string }).productId === product.id
          ? product.seller
          : null;
      return send(route, {
        conversationId: '40000000-0000-4000-8000-000000000004',
        status: 'ACCEPTED',
        threadType: 'DIRECT',
        otherUser: {
          id:
            (body && typeof body === 'object'
              ? (body as { targetUserId?: string }).targetUserId
              : undefined) ?? userIds[1],
          displayName: seller?.displayName ?? 'Synthetic Sender',
          avatarUrl: null,
        },
        product: seller
          ? { id: product.id, title: product.title, imageUrl: null, status: 'ACTIVE' }
          : null,
      });
    }
    if (path === '/chat/conversations' && method === 'GET') {
      const otherUser = {
        id: userIds[1],
        displayName: state.productConversationStarts ? 'Pessoa de teste' : 'Synthetic Sender',
      };
      return send(route, {
        items: [
          {
            id: '40000000-0000-4000-8000-000000000004',
            otherUser,
            threadType: 'DIRECT',
            status: 'ACCEPTED',
            lastMessage: state.messages.at(-1),
            ...(state.productConversationStarts
              ? { product: { id: productId, title: product.title } }
              : {}),
          },
          {
            id: '40000000-0000-4000-8000-000000000008',
            otherUser: { id: userIds[1], displayName: 'Synthetic Forward Target' },
            threadType: 'DIRECT',
            status: 'ACCEPTED',
            lastMessage: null,
          },
        ],
        nextCursor: null,
      });
    }
    if (path === '/chat/conversations/40000000-0000-4000-8000-000000000004' && method === 'GET') {
      const otherUser = {
        id: userIds[1],
        displayName: state.productConversationStarts ? 'Pessoa de teste' : 'Synthetic Sender',
      };
      const messages = state.messages.map((message) => ({
        attachmentUrl: null,
        metadata: null,
        replyToId: null,
        replyTo: null,
        deletedAt: null,
        readAt: null,
        deliveredAt: null,
        viewOnce: false,
        ...message,
      }));
      return send(route, {
        messages,
        hasMore: false,
        nextCursor: null,
        threadType: 'DIRECT',
        otherUserId: otherUser.id,
        otherUser: { ...otherUser, avatarUrl: null },
        preference: {
          isArchived: state.isArchived,
          theme: 'DEFAULT',
          backgroundUrl: null,
          muted: state.muted,
        },
      });
    }
    if (
      path ===
        '/chat/conversations/40000000-0000-4000-8000-000000000004/messages/30000000-0000-4000-8000-000000000013/view-once/open' &&
      method === 'POST'
    ) {
      state.viewOnceOpens++;
      const openingKey =
        body &&
        typeof body === 'object' &&
        'openingKey' in body &&
        typeof body.openingKey === 'string'
          ? body.openingKey
          : '';
      if (
        !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(openingKey)
      )
        return send(route, { message: 'Not found' }, 404);
      const hash = createHash('sha256').update(openingKey).digest('hex');
      if (state.viewOnceClosed || (state.viewOnceOpeningHash && state.viewOnceOpeningHash !== hash))
        return send(route, { message: 'Not found' }, 404);
      state.viewOnceOpeningHash = hash;
      return send(route, {
        messageId: '30000000-0000-4000-8000-000000000013',
        readAt: '2026-10-07T10:01:00.000Z',
        mediaUrl: '/media/view-once/synthetic',
      });
    }
    if (
      path ===
        '/chat/conversations/40000000-0000-4000-8000-000000000004/messages/30000000-0000-4000-8000-000000000013/view-once/close' &&
      method === 'POST'
    ) {
      const openingKey =
        body &&
        typeof body === 'object' &&
        'openingKey' in body &&
        typeof body.openingKey === 'string'
          ? body.openingKey
          : '';
      if (
        !state.viewOnceOpeningHash ||
        state.viewOnceOpeningHash !== createHash('sha256').update(openingKey).digest('hex')
      )
        return send(route, { message: 'Not found' }, 404);
      state.viewOnceClosed = true;
      state.viewOnceCloses++;
      return send(route, { ok: true });
    }
    if (
      path === '/chat/conversations/40000000-0000-4000-8000-000000000004/messages' &&
      method === 'POST'
    ) {
      const input = body as {
        content?: string;
        type?: string;
        clientMessageId: string;
        replyToId?: string;
        metadata?: unknown;
      };
      const item = {
        id: `80000000-0000-4000-8000-${String(state.messages.length).padStart(12, '0')}`,
        conversationId: '40000000-0000-4000-8000-000000000004',
        senderId: state.userId,
        content: input.content ?? null,
        type: input.type ?? 'TEXT',
        createdAt: '2026-10-07T10:01:00.000Z',
        ...(input.replyToId ? { replyToId: input.replyToId } : {}),
        ...(input.metadata ? { metadata: input.metadata } : {}),
      };
      if (input.type === 'LOCATION') state.locationMessages.push(item);
      state.messages.push(item);
      return send(route, item);
    }
    if (
      path === '/chat/conversations/40000000-0000-4000-8000-000000000004/read' &&
      method === 'PATCH'
    )
      return send(route, { ok: true });
    if (
      path === '/chat/conversations/40000000-0000-4000-8000-000000000004/theme' &&
      method === 'PATCH'
    ) {
      if (typeof (body as { muted?: unknown }).muted === 'boolean')
        state.muted = (body as { muted: boolean }).muted;
      return send(route, {
        isArchived: state.isArchived,
        theme: 'DEFAULT',
        backgroundUrl: null,
        muted: state.muted,
      });
    }
    if (
      path === '/chat/conversations/40000000-0000-4000-8000-000000000004/starred' &&
      method === 'GET'
    )
      return send(
        route,
        state.messages.filter((item) => state.starredIds.has(item.id)),
      );
    if (path === '/chat/messages/forward' && method === 'POST')
      return send(route, {
        forwardedCount: (body as { messageIds: string[] }).messageIds.length,
        messages: [],
      });
    if (path.endsWith('/30000000-0000-4000-8000-000000000003/react') && method === 'POST') {
      state.reactionCount = 1;
      return send(route, {
        reactions: [
          {
            emoji: (body as { emoji: string }).emoji,
            count: state.reactionCount,
            reactedByMe: true,
          },
        ],
      });
    }
    if (path.endsWith('/30000000-0000-4000-8000-000000000003/star') && method === 'POST') {
      state.starredIds.add('30000000-0000-4000-8000-000000000003');
      return send(route, { starred: true });
    }
    if (
      path === '/chat/conversations/40000000-0000-4000-8000-000000000004/archive' &&
      method === 'PATCH'
    ) {
      state.isArchived = Boolean((body as { archived: boolean }).archived);
      return send(route, { ok: true });
    }
    if (
      path === '/chat/conversations/40000000-0000-4000-8000-000000000004/messages' &&
      url.searchParams.get('type') === 'IMAGE'
    )
      return send(route, { messages: [], nextCursor: null });
    if (path === '/notifications' && method === 'GET')
      return send(route, {
        items: [
          {
            id: '90000000-0000-4000-8000-000000000009',
            content: 'Synthetic notification',
            read: false,
            createdAt: '2026-10-07T08:00:00.000Z',
          },
        ],
        nextCursor: null,
        hasMore: false,
      });
    if (path === '/notifications/read-all' && method === 'POST') {
      state.notificationsRead = true;
      return send(route, { ok: true });
    }
    if (path.startsWith('/media/story/'))
      return route.fulfill({
        status: 200,
        contentType: 'image/png',
        body: Buffer.from(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
          'base64',
        ),
      });
    if (path.startsWith('/media/')) {
      state.viewOnceFetches++;
      const key = request.headers()['x-view-once-opening'];
      const hash = key ? createHash('sha256').update(key).digest('hex') : '';
      state.viewOnceHeaderHashes.push(hash);
      if (
        !key ||
        state.viewOnceClosed ||
        !state.viewOnceOpeningHash ||
        state.viewOnceOpeningHash !== hash
      )
        return route.fulfill({
          status: 403,
          contentType: 'application/json',
          body: JSON.stringify({ message: 'Opening required' }),
        });
      if (state.viewOnceFailNextMedia) {
        state.viewOnceFailNextMedia = false;
        return route.fulfill({
          status: 503,
          contentType: 'application/json',
          body: JSON.stringify({ message: 'Retry this same opening' }),
        });
      }
      return route.fulfill({
        status: 200,
        contentType: 'image/png',
        body: Buffer.from(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
          'base64',
        ),
      });
    }
    return route.fulfill({
      status: 404,
      contentType: 'application/json',
      body: JSON.stringify({ message: `Fixture route missing: ${method} ${path}` }),
    });
  });
  return state;
}

export { disputeId, orderId, productId, userIds };

export async function finishWelcome(page: Page) {
  await page.getByRole('button', { name: 'Skip' }).click();
}

export async function waitForHydration(page: Page) {
  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(1000);
}

export async function openProtectedRoute(page: Page, state: BrowserFixture, path: string) {
  state.profile.username = 'buyer_01';
  const targetPath = new URL(path, 'http://localhost').pathname;
  await page.addInitScript((userId) => {
    localStorage.setItem(`freebay.welcome.seen.${encodeURIComponent(userId)}`, 'true');
  }, state.userId);
  await page.goto(path);
  await waitForHydration(page);
  const skip = page.getByRole('button', { name: 'Skip' });
  await expect
    .poll(
      async () => {
        if (new URL(page.url()).pathname === targetPath) return 'target';
        if (await skip.isVisible().catch(() => false)) return 'welcome';
        return 'pending';
      },
      { timeout: 10_000 },
    )
    .toMatch(/target|welcome/);
  if (await skip.isVisible().catch(() => false)) {
    await finishWelcome(page);
  }
  await expect.poll(() => new URL(page.url()).pathname, { timeout: 15_000 }).toBe(targetPath);
  await expect(page).toHaveURL((url) => url.pathname === targetPath);
}
