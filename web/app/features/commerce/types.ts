export type CartItem = {
  id: string;
  productId: string;
  quantity: number;
  subtotal: number;
  product: {
    id: string;
    title: string;
    price: number;
    sellerId: string;
    images: { id: string; url: string }[];
    seller: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
  };
};
export type Cart = { items: CartItem[]; totalItems: number; totalPrice: number };
export type OrderStatus =
  | 'PENDING'
  | 'CONFIRMED'
  | 'SHIPPED'
  | 'DELIVERED'
  | 'DISPUTED'
  | 'REFUND_PENDING'
  | 'COMPLETED'
  | 'CANCELLED';
export const orderStatuses: OrderStatus[] = [
  'PENDING',
  'CONFIRMED',
  'SHIPPED',
  'DELIVERED',
  'DISPUTED',
  'REFUND_PENDING',
  'COMPLETED',
  'CANCELLED',
];
export type EscrowStatus = 'HELD' | 'RELEASED' | 'REFUNDED';
export type Order = {
  id: string;
  buyerId: string;
  sellerId: string;
  productId: string;
  amount: number;
  platformFee: number;
  sellerAmount: number;
  status: OrderStatus;
  escrowStatus: EscrowStatus;
  createdAt: string;
  product?: { title: string; images?: { url: string }[] };
  buyer?: { id: string; displayName: string; avatarUrl?: string | null };
  seller?: { id: string; displayName: string; avatarUrl?: string | null };
  transaction?: {
    status?: string;
    paymentGroupId: string | null;
    chargeId?: string | null;
    externalId?: string | null;
  } | null;
  dispute?: { id: string; status: string } | null;
};
export type CursorPage<T> = { items: T[]; hasMore: boolean; nextCursor: string | null };
export type CheckoutGroup = {
  paymentGroupId: string;
  items: {
    orderId: string;
    productId: string;
    productTitle: string;
    quantity: number;
    amount: number;
  }[];
  totalOrders: number;
  totalAmount: number;
  checkoutUrl: string | null;
  expiresAt: string | null;
};
export type CheckoutRecovery = {
  status: 'CHECKING' | 'PAID';
  paymentGroupId: string;
  orderIds: string[];
  totalAmount: number;
  checkoutUrl: string | null;
  paymentIntentClientSecret: string | null;
  expiresAt: string | null;
};
export function canonicalCheckoutGroup(group: CheckoutGroup) {
  return { totalAmount: group.totalAmount, totalOrders: group.totalOrders, items: group.items };
}
const preReservationCheckoutRejections = [
  'Adicione seu CPF no perfil antes de realizar uma compra',
  'Carrinho vazio',
  'Você não pode comprar seu próprio produto',
  'Um ou mais produtos do carrinho não estão disponíveis',
  'Um ou mais produtos não estão mais disponíveis',
];

export function checkoutFailureIsDefinitive(
  status: number | undefined,
  code?: string,
  message?: string,
) {
  // ponytail: only audited pre-reservation messages are safe; widen only with a verified backend phase contract.
  return (
    status === 400 &&
    code === 'BAD_REQUEST' &&
    Boolean(
      message &&
        (preReservationCheckoutRejections.includes(message) ||
          message.startsWith('Estoque insuficiente para ')),
    )
  );
}
export type ReviewEligibility = {
  canReview: boolean;
  reviewType?: 'BUYER_REVIEWING_SELLER' | 'SELLER_REVIEWING_BUYER';
  reason?: string;
};
export type Review = {
  id: string;
  reviewerId: string;
  reviewedId: string;
  orderId: string;
  type: 'BUYER_REVIEWING_SELLER' | 'SELLER_REVIEWING_BUYER';
  score: number;
  comment: string | null;
  images?: { id: string; url: string; order: number }[];
  createdAt: string;
  reviewer?: { id: string; displayName: string; avatarUrl: string | null; isVerified?: boolean };
};
export type Dispute = {
  id: string;
  orderId: string;
  openedById: string;
  reason: string;
  status: string;
  resolution: string | null;
  buyerEvidence: unknown;
  sellerEvidence: unknown;
  createdAt: string;
  expiresAt: string;
  resolvedAt: string | null;
  order: {
    buyerId: string;
    sellerId: string;
    buyer: { displayName: string };
    seller: { displayName: string };
    product: { title: string };
  };
};
export type Wallet = { balance: number; pendingBalance: number; availableBalance: number };
export type WalletEntry = {
  id: string;
  orderId: string | null;
  amount: number;
  kind: string;
  reason: string;
  createdAt: string;
  productTitle: string | null;
};
export type ConnectStatus = {
  status: 'onboarding-required' | 'requirements-due' | 'restricted' | 'transfer-ready';
  requirementsDue: string[];
};

export function orderParticipants(order: Order, userId: string) {
  return {
    buyer: order.buyerId === userId,
    seller: order.sellerId === userId,
  };
}

export function reviewTargetId(order: Order, reviewType: ReviewEligibility['reviewType']) {
  if (reviewType === 'BUYER_REVIEWING_SELLER') return order.sellerId;
  if (reviewType === 'SELLER_REVIEWING_BUYER') return order.buyerId;
  return null;
}

export function paymentReturnState(pathname: string): 'pending' | 'cancelled' {
  return pathname.endsWith('/cancel') ? 'cancelled' : 'pending';
}

export function safeCheckoutUrl(raw: string): string | null {
  try {
    const url = new URL(raw);
    if (url.protocol !== 'https:' || url.username || url.password || url.port) return null;
    return url.hostname === 'checkout.stripe.com' || url.hostname.endsWith('.checkout.stripe.com')
      ? url.href
      : null;
  } catch {
    return null;
  }
}

export function safeConnectUrl(raw: string): string | null {
  try {
    const url = new URL(raw);
    if (url.protocol !== 'https:' || url.username || url.password || url.port) return null;
    const host = url.hostname;
    return ['connect.stripe.com', 'dashboard.stripe.com'].some(
      (domain) => host === domain || host.endsWith(`.${domain}`),
    )
      ? url.href
      : null;
  } catch {
    return null;
  }
}

export function canSubmitEvidence(status: string, isParty: boolean) {
  return isParty && status !== 'ESCALATED' && status !== 'RESOLVED' && status !== 'CANCELLED';
}

export function canWithdrawDispute(status: string, isOpener: boolean) {
  return isOpener && ['OPEN', 'AWAITING_SELLER', 'AWAITING_BUYER', 'ESCALATED'].includes(status);
}
