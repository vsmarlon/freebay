import { describe, expect, it } from 'vitest';
import { checkoutGroupSchema, orderSchema, walletSchema } from './schemas';

const order = {
  id: 'o1',
  buyerId: 'b1',
  sellerId: 's1',
  productId: 'p1',
  amount: 10000,
  platformFee: 500,
  sellerAmount: 9500,
  status: 'PENDING',
  escrowStatus: 'HELD',
  createdAt: '2026-11-09T12:00:00.000Z',
};

describe('commerce boundary schemas', () => {
  it('accepts integer cents and ignores unknown fields', () => {
    expect(orderSchema.parse({ ...order, futureField: true })).toMatchObject({ amount: 10000 });
  });

  it('rejects fractional money', () => {
    expect(() => orderSchema.parse({ ...order, amount: 100.5 })).toThrow();
  });

  it('rejects an unknown order status', () => {
    expect(() => orderSchema.parse({ ...order, status: 'WHATEVER' })).toThrow();
  });

  it('validates the checkout group totals', () => {
    const group = {
      paymentGroupId: 'pg1',
      items: [
        { orderId: 'o1', productId: 'p1', productTitle: 'Camera', quantity: 1, amount: 10000 },
      ],
      totalOrders: 1,
      totalAmount: 10000,
      checkoutUrl: null,
      expiresAt: null,
    };
    expect(checkoutGroupSchema.parse(group).totalAmount).toBe(10000);
    expect(() => checkoutGroupSchema.parse({ ...group, totalAmount: -1 })).toThrow();
  });

  it('requires every wallet balance in cents', () => {
    expect(
      walletSchema.parse({ balance: 0, pendingBalance: 100, availableBalance: 50 }).balance,
    ).toBe(0);
    expect(() => walletSchema.parse({ balance: 0, pendingBalance: 100 })).toThrow();
  });
});
