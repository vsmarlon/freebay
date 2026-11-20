import { createServer } from 'node:http';

// DTO-shaped synthetic responses for the public SSR checks and the
// real-browser commerce walkthrough; never represents DB/provider evidence.
// The state machine mirrors e2e/journeys/browser-fixture.ts so both lanes
// exercise the same contract shapes.
const product = {
  id: 'web-fixture-camera',
  title: 'Câmera analógica',
  description: 'Câmera em ótimo estado, testada e pronta para uso.',
  price: 10000,
  condition: 'USED',
  categoryId: 'photo',
  sellerId: '20000000-0000-4000-8000-000000000002',
  status: 'ACTIVE',
  quantity: 3,
  soldCount: 0,
  createdAt: '2026-10-01T12:00:00.000Z',
  seller: {
    id: '20000000-0000-4000-8000-000000000002',
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
const userId = '10000000-0000-4000-8000-000000000001';
const sellerId = '20000000-0000-4000-8000-000000000002';
const accessToken = `eyJhbGciOiJub25lIn0.${Buffer.from(
  JSON.stringify({ sub: userId, exp: 4102444800 }),
).toString('base64url')}.x`;

const state = {
  profile: {
    id: userId,
    displayName: 'Synthetic Buyer',
    username: null,
    avatarUrl: null,
    role: 'ADMIN',
  },
  signedIn: false,
  cartQuantity: 0,
  orderStatus: 'CONFIRMED',
  orderEscrow: 'HELD',
  dispute: null,
};

const send = (res, data, status = 200, headers = {}) => {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8', ...headers });
  res.end(JSON.stringify({ data }));
};
const fail = (res, status, message) => {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ message }));
};
const hasSession = (req) => (req.headers.cookie ?? '').includes('freebay_web_refresh=');
const requireSession = (req, res) => {
  if (!hasSession(req)) {
    fail(res, 401, 'Unauthorized');
    return false;
  }
  return true;
};

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return {};
  }
}

// Mirrors backend availableOrderActions for the synthetic buyer
// (orders/domain/order-state.ts).
function buyerAllowedActions() {
  if (state.orderStatus === 'CONFIRMED') return ['CANCEL', 'CONFIRM_DELIVERY', 'OPEN_DISPUTE'];
  if (state.orderStatus === 'SHIPPED') return ['CONFIRM_DELIVERY', 'OPEN_DISPUTE'];
  if (state.orderStatus === 'DELIVERED')
    return ['CONFIRM_DELIVERY', state.dispute ? 'REOPEN_DISPUTE' : 'OPEN_DISPUTE'];
  if (state.orderStatus === 'DISPUTED') return ['VIEW_DISPUTE'];
  return [];
}

function orderView() {
  return {
    id: orderId,
    buyerId: userId,
    sellerId,
    productId: product.id,
    amount: 12500,
    platformFee: 0,
    sellerAmount: 12500,
    status: state.orderStatus,
    escrowStatus: state.orderEscrow,
    createdAt: '2026-10-07T10:00:00.000Z',
    product: { title: product.title },
    buyer: { id: userId, displayName: state.profile.displayName, avatarUrl: null },
    seller: { id: sellerId, displayName: product.seller.displayName, avatarUrl: null },
    transaction: {
      status: state.orderStatus === 'PENDING' ? 'PENDING' : 'PAID',
      paymentGroupId,
      chargeId: state.orderStatus === 'PENDING' ? null : 'ch_fixture_order',
      externalId: null,
    },
    dispute: state.dispute ? { id: state.dispute.id, status: state.dispute.status } : null,
  };
}

function disputeView() {
  const dispute = state.dispute;
  return {
    id: dispute.id,
    orderId,
    openedById: userId,
    reason: dispute.reason,
    status: dispute.status,
    resolution: null,
    buyerEvidence: dispute.buyerEvidence,
    sellerEvidence: null,
    createdAt: '2026-10-07T11:00:00.000Z',
    expiresAt: '2026-10-10T11:00:00.000Z',
    resolvedAt: null,
    order: {
      buyerId: userId,
      sellerId,
      buyer: { displayName: state.profile.displayName },
      seller: { displayName: product.seller.displayName },
      product: { title: product.title },
    },
  };
}

const ssrObservations = [];

createServer(async (req, res) => {
  const url = new URL(req.url ?? '/', 'http://127.0.0.1:3333');
  const path = url.pathname;
  const method = req.method;
  const body = ['POST', 'PATCH', 'PUT'].includes(method) ? await readBody(req) : {};
  if (path === '/health') return send(res, { status: 'ok' });
  if (path === '/__test/ssr-observations') return send(res, ssrObservations.splice(0));
  if (path.startsWith('/products') || path === '/categories')
    ssrObservations.push({
      path,
      hasAuthorization: Boolean(req.headers.authorization),
      hasCookie: Boolean(req.headers.cookie),
    });

  if (path === '/products' && method === 'GET')
    return send(res, { products: [product], nextCursor: null });
  if (path === `/products/${product.id}` && method === 'GET') return send(res, { product });
  if (path === '/categories' && method === 'GET')
    return send(res, {
      categories: [{ id: 'photo', name: 'Fotografia', parentId: null, children: [] }],
    });

  if (path === '/auth/web/magic-link/request' && method === 'POST')
    return send(res, { accepted: true });
  if (path === '/auth/web/magic-link/consume' && method === 'POST') {
    state.signedIn = true;
    return send(res, { user: { ...state.profile } }, 200, {
      'set-cookie': 'freebay_web_refresh=synthetic-refresh-cookie; HttpOnly; Path=/; SameSite=Lax',
    });
  }
  if (path === '/auth/complete-profile' && method === 'POST') {
    state.profile.username = body.username ?? state.profile.username;
    return send(res, { user: { ...state.profile } });
  }
  if (path === '/auth/web/session/access-token' && method === 'POST') {
    if (!requireSession(req, res)) return;
    return send(res, { token: accessToken });
  }
  if (path === '/auth/web/session/refresh' && method === 'POST') {
    if (!requireSession(req, res)) return;
    return send(res, { token: accessToken });
  }
  if (path === '/auth/web/session/logout' && method === 'POST') {
    state.signedIn = false;
    return send(res, { ok: true }, 200, { 'set-cookie': 'freebay_web_refresh=; Max-Age=0' });
  }
  if (path === '/auth/web/step-up' && method === 'POST') {
    if (!requireSession(req, res)) return;
    if (!req.headers.authorization) return fail(res, 401, 'Unauthorized');
    return send(res, { stepUpToken: 'synthetic-step-up-token' });
  }
  if (path === '/users/me' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, { ...state.profile });
  }
  if (path === '/users/me/stats' && method === 'GET')
    return send(res, { followersCount: 0, followingCount: 0, postsCount: 0, productsCount: 0 });
  if (path === `/favorites/check/${product.id}` && method === 'GET')
    return send(res, { isFavorited: false });
  if (path === `/favorites/${product.id}` && method === 'POST')
    return send(res, { isFavorited: true });
  if (path === '/notifications' && method === 'GET')
    return send(res, { items: [], nextCursor: null, hasMore: false });
  if (path === '/chat/conversations' && method === 'GET')
    return send(res, { items: [], nextCursor: null });

  if (path === '/cart' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, { items: [], totalItems: 0, totalPrice: 0 });
  }
  if (path === `/cart/${product.id}` && method === 'POST') {
    if (!requireSession(req, res)) return;
    state.cartQuantity = Math.min(3, body.quantity ?? 1);
    return send(res, { item: { id: 'cart-row-fixture', quantity: state.cartQuantity } });
  }
  if (path === '/cart/checkout/recovery' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, null);
  }
  if (path === '/cart/checkout' && method === 'POST') {
    if (!requireSession(req, res)) return;
    state.orderStatus = 'PENDING';
    state.orderEscrow = 'HELD';
    return send(res, {
      paymentGroupId,
      items: [
        {
          orderId,
          productId: product.id,
          productTitle: product.title,
          quantity: state.cartQuantity || 1,
          amount: 12500,
        },
      ],
      totalOrders: 1,
      totalAmount: 12500,
      checkoutUrl: 'https://checkout.stripe.com/c/pay/synthetic',
      expiresAt: null,
    });
  }

  if (path === '/orders/my/purchases' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, {
      items: state.orderStatus ? [orderView()] : [],
      hasMore: false,
      nextCursor: null,
    });
  }
  if (path === '/orders/my/sales' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, { items: [], hasMore: false, nextCursor: null });
  }
  if (path === `/orders/${orderId}` && method === 'GET') {
    if (!requireSession(req, res)) return;
    if (!state.orderStatus) return fail(res, 404, 'Not found');
    return send(res, { order: orderView(), allowedActions: buyerAllowedActions() });
  }
  if (path === `/orders/${orderId}/ship` && method === 'PATCH') {
    if (!requireSession(req, res)) return;
    state.orderStatus = 'SHIPPED';
    return send(res, { order: orderView() });
  }
  if (path === `/orders/${orderId}/deliver` && method === 'PATCH') {
    if (!requireSession(req, res)) return;
    state.orderStatus = 'DELIVERED';
    return send(res, { order: orderView() });
  }
  if (path === `/orders/${orderId}/confirm` && method === 'PATCH') {
    if (!requireSession(req, res)) return;
    state.orderStatus = 'COMPLETED';
    state.orderEscrow = 'RELEASED';
    return send(res, { order: orderView() });
  }
  if (path === `/orders/${orderId}/cancel` && method === 'PATCH') {
    if (!requireSession(req, res)) return;
    state.orderStatus = 'CANCELLED';
    return send(res, { order: orderView() });
  }
  if (path === `/payments/checkout/${orderId}` && method === 'POST') {
    if (!requireSession(req, res)) return;
    return send(res, { checkoutUrl: 'https://checkout.stripe.com/c/pay/synthetic' });
  }
  if (path === `/reviews/orders/${orderId}/can-review` && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, { canReview: false, reason: 'ORDER_NOT_COMPLETED' });
  }
  if (path.startsWith('/reviews/users/') && method === 'GET')
    return send(res, { reviews: [], total: 0, offset: 0, limit: 50 });

  if (path === '/disputes' && method === 'POST') {
    if (!requireSession(req, res)) return;
    if (state.dispute) {
      state.dispute.status = 'OPEN';
      state.dispute.reason = body.reason ?? state.dispute.reason;
    } else {
      state.dispute = {
        id: disputeId,
        status: 'OPEN',
        reason: body.reason ?? 'Fixture dispute',
        buyerEvidence: null,
      };
    }
    state.orderStatus = 'DISPUTED';
    return send(res, { id: state.dispute.id });
  }
  if (path === '/disputes' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, { disputes: state.dispute ? [disputeView()] : [] });
  }
  if (path === `/disputes/${disputeId}` && method === 'GET') {
    if (!requireSession(req, res)) return;
    if (!state.dispute) return fail(res, 404, 'Not found');
    return send(res, { dispute: disputeView() });
  }
  if (path === `/disputes/${disputeId}/evidence` && method === 'POST') {
    if (!requireSession(req, res)) return;
    if (state.dispute) {
      state.dispute.status = 'AWAITING_SELLER';
      state.dispute.buyerEvidence = body.evidence ?? null;
    }
    return send(res, { ok: true });
  }
  if (path === `/disputes/${disputeId}/withdraw` && method === 'PATCH') {
    if (!requireSession(req, res)) return;
    if (state.dispute) {
      state.dispute.status = 'CANCELLED';
      state.orderStatus = 'DELIVERED';
    }
    return send(res, { ok: true });
  }
  if (path === `/disputes/${disputeId}/resolve` && method === 'PATCH') {
    if (!requireSession(req, res)) return;
    if (state.dispute) {
      state.dispute.status = 'RESOLVED';
      if (body.winner === 'BUYER') {
        state.orderStatus = 'CANCELLED';
        state.orderEscrow = 'REFUNDED';
      } else {
        state.orderStatus = 'COMPLETED';
        state.orderEscrow = 'RELEASED';
      }
    }
    return send(res, { ok: true });
  }
  if (path === '/admin/disputes' && method === 'GET') {
    if (!requireSession(req, res)) return;
    if (!state.dispute) return send(res, { disputes: [] });
    const status = url.searchParams.get('status');
    if (status && status !== 'ALL' && state.dispute.status !== status)
      return send(res, { disputes: [] });
    return send(res, {
      disputes: [
        {
          ...disputeView(),
          winner: null,
          resolution: null,
          order: {
            id: orderId,
            buyerId: userId,
            sellerId,
            amount: 12500,
            status: state.orderStatus ?? 'DISPUTED',
            buyer: { id: userId, displayName: state.profile.displayName },
            seller: { id: sellerId, displayName: product.seller.displayName },
            product: { title: product.title, imageUrl: null },
          },
          openedBy: { id: userId, displayName: state.profile.displayName },
        },
      ],
    });
  }

  if (path === '/wallet' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, { balance: 5000, pendingBalance: 0, availableBalance: 5000 });
  }
  if (path === '/wallet/transactions' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, { items: [], hasMore: false, nextCursor: null });
  }
  if (path === '/payments/connect/status' && method === 'GET') {
    if (!requireSession(req, res)) return;
    return send(res, { status: 'transfer-ready', requirementsDue: [] });
  }
  if (path === '/payments/connect/onboarding' && method === 'POST') {
    if (!requireSession(req, res)) return;
    return send(res, { onboardingUrl: 'https://connect.stripe.com/synthetic-onboarding' });
  }
  if (path === '/payments/connect/dashboard' && method === 'POST') {
    if (!requireSession(req, res)) return;
    return send(res, { dashboardUrl: 'https://dashboard.stripe.com/synthetic' });
  }

  res.writeHead(404, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ message: `Fixture has no route for ${method} ${path}` }));
}).listen(Number(process.env.PORT ?? 3333), '127.0.0.1');
