import { describe, expect, it } from 'vitest';
import { canSubmitEvidence, canonicalCheckoutGroup, checkoutFailureIsDefinitive, orderActions, paymentReturnState, reviewTargetId, safeCheckoutUrl, safeConnectUrl, type Order } from './types';

const baseOrder: Order = {
  id: 'order-1', buyerId: 'buyer-1', sellerId: 'seller-1', productId: 'product-1', amount: 12_500,
  platformFee: 1_250, sellerAmount: 11_250, status: 'SHIPPED', escrowStatus: 'HELD', createdAt: '2026-01-01T00:00:00Z',
};

describe('server-driven commerce affordances', () => {
  it('only offers each order transition to the participant and source status that permits it', () => {
    expect(orderActions(baseOrder, 'buyer-1')).toMatchObject({ buyer: true, seller: false, markDelivered: true, confirmReceipt: true, markShipped: false, cancel: false, openDispute: true });
    expect(orderActions(baseOrder, 'seller-1')).toMatchObject({ buyer: false, seller: true, markDelivered: false, confirmReceipt: false, markShipped: false, cancel: false, openDispute: true });
    expect(orderActions({ ...baseOrder, status: 'CONFIRMED' }, 'seller-1').markShipped).toBe(true);
    expect(orderActions({ ...baseOrder, status: 'PENDING' }, 'buyer-1').cancel).toBe(true);
    expect(orderActions({ ...baseOrder, status: 'CONFIRMED' }, 'seller-1').cancel).toBe(true);
    expect(orderActions({ ...baseOrder, status: 'PENDING', paymentGroupId: 'group-1' }, 'buyer-1').cancel).toBe(false);
    expect(orderActions({ ...baseOrder, status: 'SHIPPED' }, 'other').openDispute).toBe(false);
  });

  it('selects the opposite party for the server-provided review type', () => {
    expect(reviewTargetId(baseOrder, 'BUYER_REVIEWING_SELLER')).toBe('seller-1');
    expect(reviewTargetId(baseOrder, 'SELLER_REVIEWING_BUYER')).toBe('buyer-1');
    expect(reviewTargetId(baseOrder, undefined)).toBeNull();
  });

  it('allows evidence only from dispute parties before a terminal status', () => {
    expect(canSubmitEvidence('OPEN', true)).toBe(true);
    expect(canSubmitEvidence('RESOLVED', true)).toBe(false);
    expect(canSubmitEvidence('CANCELLED', true)).toBe(false);
    expect(canSubmitEvidence('OPEN', false)).toBe(false);
  });

  it('does not treat a browser success query as payment settlement', () => {
    expect(paymentReturnState('/payments/success')).toBe('pending');
    expect(paymentReturnState('/payments/cancel')).toBe('cancelled');
  });

  it('renders the group total from the server instead of repricing from item amounts', () => {
    const group = canonicalCheckoutGroup({
      paymentGroupId: 'group-1', totalOrders: 2, totalAmount: 13_450,
      items: [
        { orderId: 'order-1', productId: 'p-1', productTitle: 'First', quantity: 1, amount: 6_000 },
        { orderId: 'order-2', productId: 'p-2', productTitle: 'Second', quantity: 2, amount: 6_000 },
      ],
      checkoutUrl: null, expiresAt: null,
    });
    expect(group.totalAmount).toBe(13_450);
    expect(group.totalOrders).toBe(2);
  });
});

describe('hosted provider redirects', () => {
  it('accepts only credential-free HTTPS Stripe checkout and Connect domains', () => {
    expect(safeCheckoutUrl('https://checkout.stripe.com/c/pay')).not.toBeNull();
    expect(safeCheckoutUrl('https://checkout.stripe.com.attacker.example/pay')).toBeNull();
    expect(safeCheckoutUrl('https://user:pass@checkout.stripe.com/pay')).toBeNull();
    expect(safeCheckoutUrl('https://checkout.stripe.com:8443/pay')).toBeNull();
    expect(safeCheckoutUrl('javascript:alert(1)')).toBeNull();
    expect(safeConnectUrl('https://connect.stripe.com/setup/abc')).not.toBeNull();
    expect(safeConnectUrl('https://dashboard.stripe.com/express')).not.toBeNull();
    expect(safeConnectUrl('https://attacker.example/?next=https://connect.stripe.com')).toBeNull();
    expect(safeConnectUrl('https://user:pass@connect.stripe.com/setup/abc')).toBeNull();
  });
});

describe('checkout retry safety', () => {
  it('allows retry after authoritative pre-payment rejection but holds ambiguous outcomes', () => {
    expect(checkoutFailureIsDefinitive(400, 'BAD_REQUEST', 'Carrinho vazio')).toBe(true);
    expect(checkoutFailureIsDefinitive(400, 'BAD_REQUEST', 'Estoque insuficiente para item')).toBe(true);
    expect(checkoutFailureIsDefinitive(400, 'BAD_REQUEST', 'Falha desconhecida')).toBe(false);
    expect(checkoutFailureIsDefinitive(400)).toBe(false);
    expect(checkoutFailureIsDefinitive(401, undefined, 'Session changed during request')).toBe(false);
    expect(checkoutFailureIsDefinitive(409)).toBe(false);
    expect(checkoutFailureIsDefinitive(500)).toBe(false);
    expect(checkoutFailureIsDefinitive(undefined)).toBe(false);
  });
});
