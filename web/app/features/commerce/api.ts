import { api } from '../../core/api';
import {
  checkoutGroupSchema,
  checkoutRecoverySchema,
  orderEnvelopeSchema,
  orderSchema,
  ordersPageSchema,
  orderWithActionsSchema,
  walletSchema,
} from './schemas';
import type {
  Cart,
  ConnectStatus,
  CursorPage,
  Dispute,
  Review,
  ReviewEligibility,
  WalletEntry,
} from './types';

const query = (cursor?: string | null, status?: string, limit = 20) => {
  const params = new URLSearchParams({ limit: String(limit) });
  if (cursor) params.set('cursor', cursor);
  if (status && status !== 'ALL') params.set('status', status);
  return params.toString();
};

export const commerceApi = {
  cart: (signal?: AbortSignal) => api.get<Cart>('/cart', { signal }),
  productStock: (productId: string, signal?: AbortSignal) =>
    api.get<{ product: { quantity: number; soldCount: number; status: string } }>(
      `/products/${encodeURIComponent(productId)}`,
      { signal },
    ),
  addToCart: (productId: string, quantity = 1) =>
    api.post<{ item: { id: string; quantity: number } }>(
      `/cart/${encodeURIComponent(productId)}`,
      { quantity },
      { retryAfterRefresh: false },
    ),
  updateCartItem: (productId: string, quantity: number) =>
    api.patch(`/cart/${encodeURIComponent(productId)}`, { quantity }, { retryAfterRefresh: false }),
  removeCartItem: (productId: string) =>
    api.patch(`/cart/${encodeURIComponent(productId)}/remove`, undefined, {
      retryAfterRefresh: false,
    }),
  clearCart: () => api.patch('/cart/clear', undefined, { retryAfterRefresh: false }),
  checkout: () =>
    api.post(
      '/cart/checkout',
      { mode: 'session' },
      {
        retryAfterRefresh: false,
        schema: checkoutGroupSchema,
      },
    ),
  checkoutRecovery: (signal?: AbortSignal) =>
    api.get('/cart/checkout/recovery?mode=session', {
      signal,
      schema: checkoutRecoverySchema.nullable(),
    }),
  createOrder: (productId: string) =>
    api.post('/orders', { productId }, { retryAfterRefresh: false, schema: orderSchema }),
  paymentSession: (orderId: string) =>
    api.post<{ checkoutUrl: string }>(
      `/payments/checkout/${encodeURIComponent(orderId)}`,
      undefined,
      { retryAfterRefresh: false },
    ),
  purchases: (cursor?: string | null, signal?: AbortSignal, status?: string, limit = 20) =>
    api.get(`/orders/my/purchases?${query(cursor, status, limit)}`, {
      signal,
      schema: ordersPageSchema,
    }),
  sales: (status?: string, cursor?: string | null, signal?: AbortSignal) =>
    api.get(`/orders/my/sales?${query(cursor, status)}`, { signal, schema: ordersPageSchema }),
  order: async (id: string, signal?: AbortSignal) =>
    (await api.get(`/orders/${encodeURIComponent(id)}`, { signal, schema: orderEnvelopeSchema }))
      .order,
  orderWithActions: (id: string, signal?: AbortSignal) =>
    api.get(`/orders/${encodeURIComponent(id)}`, { signal, schema: orderWithActionsSchema }),
  ship: (id: string) =>
    api.patch(`/orders/${encodeURIComponent(id)}/ship`, undefined, { retryAfterRefresh: false }),
  markDelivered: (id: string) =>
    api.patch(`/orders/${encodeURIComponent(id)}/deliver`, undefined, { retryAfterRefresh: false }),
  confirmDelivery: (id: string) =>
    api.patch(`/orders/${encodeURIComponent(id)}/confirm`, undefined, { retryAfterRefresh: false }),
  cancel: (id: string, reason: string, token: string) =>
    api.patch(
      `/orders/${encodeURIComponent(id)}/cancel`,
      { reason },
      { headers: { 'x-step-up-token': token }, retryAfterRefresh: false },
    ),
  reviewEligibility: (id: string, signal?: AbortSignal) =>
    api.get<ReviewEligibility>(`/reviews/orders/${encodeURIComponent(id)}/can-review`, { signal }),
  createReview: (
    id: string,
    body: {
      reviewedId: string;
      type: Review['type'];
      score: number;
      comment?: string;
      imageIds?: string[];
    },
  ) => api.post(`/reviews/orders/${encodeURIComponent(id)}`, body, { retryAfterRefresh: false }),
  uploadReviewImage: (id: string, file: File) => {
    const form = new FormData();
    form.append('image', file);
    return api.post<{ imageId: string; url: string }>(
      `/reviews/orders/${encodeURIComponent(id)}/images`,
      form,
      { retryAfterRefresh: false },
    );
  },
  reviews: (userId: string, signal?: AbortSignal) =>
    api.get<{ reviews: Review[]; total: number; offset: number; limit: number }>(
      `/reviews/users/${encodeURIComponent(userId)}?offset=0&limit=50`,
      { signal },
    ),
  openDispute: (orderId: string, reason: string) =>
    api.post<{ id: string }>('/disputes', { orderId, reason }, { retryAfterRefresh: false }),
  disputes: (signal?: AbortSignal) => api.get<{ disputes: Dispute[] }>('/disputes', { signal }),
  dispute: (id: string, signal?: AbortSignal) =>
    api.get<{ dispute: Dispute }>(`/disputes/${encodeURIComponent(id)}`, { signal }),
  submitEvidence: (id: string, evidence: string) =>
    api.post(
      `/disputes/${encodeURIComponent(id)}/evidence`,
      { evidence },
      { retryAfterRefresh: false },
    ),
  withdrawDispute: (id: string) =>
    api.patch(`/disputes/${encodeURIComponent(id)}/withdraw`, undefined, {
      retryAfterRefresh: false,
    }),
  wallet: (signal?: AbortSignal) => api.get('/wallet', { signal, schema: walletSchema }),
  ledger: (cursor?: string | null, signal?: AbortSignal) =>
    api.get<CursorPage<WalletEntry>>(`/wallet/transactions?${query(cursor)}`, { signal }),
  connectStatus: (signal?: AbortSignal) =>
    api.get<ConnectStatus>('/payments/connect/status', { signal }),
  connectOnboarding: () =>
    api.post<{ onboardingUrl: string }>('/payments/connect/onboarding', undefined, {
      retryAfterRefresh: false,
    }),
  connectDashboard: (token: string) =>
    api.post<{ dashboardUrl: string }>('/payments/connect/dashboard', undefined, {
      headers: { 'x-step-up-token': token },
      retryAfterRefresh: false,
    }),
  orderConversation: async (orderId: string, signal?: AbortSignal) => {
    let cursor: string | null = null;
    do {
      const params = new URLSearchParams({ limit: '50' });
      if (cursor) params.set('cursor', cursor);
      const page = await api.get<
        CursorPage<{ id: string; threadType: 'DIRECT' | 'ORDER'; orderInfo?: { id: string } }>
      >(`/chat/conversations?${params}`, { signal });
      const found = page.items.find(
        (thread) => thread.threadType === 'ORDER' && thread.orderInfo?.id === orderId,
      );
      if (found) return found;
      cursor = page.nextCursor;
    } while (cursor);
    return null;
  },
  startConversation: (targetUserId: string) =>
    api.post<{ conversationId: string }>(
      '/chat/conversations',
      { targetUserId },
      { retryAfterRefresh: false },
    ),
};
