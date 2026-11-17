import { DisputeStatus, EscrowStatus, OrderStatus, TransactionStatus } from '@prisma/client';
import {
  OrderParticipantView,
  availableOrderActions,
  canCancelOrder,
  canConfirmDelivery,
  canMarkDelivered,
  canMarkShipped,
  canOpenDispute,
  canReopenDispute,
} from './order-state';

const now = new Date('2026-11-09T12:00:00.000Z');
const hours = (value: number) => value * 60 * 60 * 1000;
const transaction = (overrides: Partial<NonNullable<OrderParticipantView['transaction']>> = {}) => ({
  status: TransactionStatus.PAID,
  paymentGroupId: null,
  chargeId: 'ch_1',
  externalId: 'pi_1',
  ...overrides,
});

function order(overrides: Partial<OrderParticipantView> = {}): OrderParticipantView {
  return {
    status: OrderStatus.CONFIRMED,
    escrowStatus: EscrowStatus.HELD,
    cancellationReason: null,
    deliveryConfirmedAt: null,
    createdAt: new Date(now.getTime() - hours(1)),
    buyerId: 'buyer-1',
    sellerId: 'seller-1',
    dispute: null,
    transaction: transaction(),
    ...overrides,
  };
}

describe('cancel', () => {
  it('allows a participant to cancel an unpaid PENDING order with no transaction', () => {
    expect(canCancelOrder(order({ status: OrderStatus.PENDING, transaction: null }), 'buyer-1')).toBe(true);
  });

  it('refuses a PENDING order whose payment belongs to a cart group', () => {
    expect(canCancelOrder(order({
      status: OrderStatus.PENDING,
      transaction: transaction({ status: TransactionStatus.PENDING, paymentGroupId: 'group-1' }),
    }), 'buyer-1')).toBe(false);
  });

  it('refuses a PENDING order whose pending payment has no provider identity', () => {
    expect(canCancelOrder(order({
      status: OrderStatus.PENDING,
      transaction: transaction({ status: TransactionStatus.PENDING, externalId: null }),
    }), 'buyer-1')).toBe(false);
  });

  it('allows cancelling a CONFIRMED order only with a captured, refundable payment', () => {
    expect(canCancelOrder(order(), 'buyer-1')).toBe(true);
    expect(canCancelOrder(order({ transaction: transaction({ chargeId: null, externalId: null }) }), 'buyer-1')).toBe(false);
    expect(canCancelOrder(order({ transaction: transaction({ status: TransactionStatus.PENDING }) }), 'buyer-1')).toBe(false);
  });

  it('refuses an outsider and terminal states', () => {
    expect(canCancelOrder(order(), 'other')).toBe(false);
    expect(canCancelOrder(order({ status: OrderStatus.COMPLETED }), 'buyer-1')).toBe(false);
    expect(canCancelOrder(order({ status: OrderStatus.REFUND_PENDING }), 'buyer-1')).toBe(false);
  });
});

describe('handover and delivery', () => {
  it('lets only the seller mark a paid CONFIRMED order as handover', () => {
    expect(canMarkShipped(order(), 'seller-1')).toBe(true);
    expect(canMarkShipped(order(), 'buyer-1')).toBe(false);
    expect(canMarkShipped(order({ cancellationReason: 'refund' }), 'seller-1')).toBe(false);
    expect(canMarkShipped(order({ transaction: transaction({ status: TransactionStatus.PENDING }) }), 'seller-1')).toBe(false);
  });

  it('lets only the buyer mark a paid SHIPPED order as received', () => {
    const shipped = order({ status: OrderStatus.SHIPPED });
    expect(canMarkDelivered(shipped, 'buyer-1')).toBe(true);
    expect(canMarkDelivered(shipped, 'seller-1')).toBe(false);
    expect(canMarkDelivered(order(), 'buyer-1')).toBe(false);
  });

  it('confirms delivery only while escrow is held and the payment is captured', () => {
    expect(canConfirmDelivery(order(), 'buyer-1')).toBe(true);
    expect(canConfirmDelivery(order({ status: OrderStatus.DELIVERED }), 'buyer-1')).toBe(true);
    expect(canConfirmDelivery(order({ escrowStatus: EscrowStatus.RELEASED }), 'buyer-1')).toBe(false);
    expect(canConfirmDelivery(order({ cancellationReason: 'refund' }), 'buyer-1')).toBe(false);
    expect(canConfirmDelivery(order({ status: OrderStatus.REFUND_PENDING }), 'buyer-1')).toBe(false);
  });
});

describe('dispute opening and reopening', () => {
  it('opens within 48 hours of the delivery clock for CONFIRMED', () => {
    expect(canOpenDispute(order(), 'buyer-1', now)).toBe(true);
    expect(canOpenDispute(order({
      deliveryConfirmedAt: new Date(now.getTime() - hours(49)),
    }), 'buyer-1', now)).toBe(false);
  });

  it('does not apply the window while handover has not been confirmed', () => {
    expect(canOpenDispute(order({
      status: OrderStatus.SHIPPED,
      deliveryConfirmedAt: new Date(now.getTime() - hours(200)),
    }), 'buyer-1', now)).toBe(true);
  });

  it('reopens only a withdrawn dispute inside the window', () => {
    expect(canReopenDispute(order({ dispute: { status: DisputeStatus.CANCELLED } }), 'buyer-1', now)).toBe(true);
    expect(canReopenDispute(order({ dispute: { status: DisputeStatus.RESOLVED } }), 'buyer-1', now)).toBe(false);
    expect(canReopenDispute(order(), 'buyer-1', now)).toBe(false);
  });

  it('refuses a second open dispute and outsiders', () => {
    expect(canOpenDispute(order({ dispute: { status: DisputeStatus.OPEN } }), 'buyer-1', now)).toBe(false);
    expect(canOpenDispute(order(), 'other', now)).toBe(false);
  });
});

describe('availableOrderActions', () => {
  it('returns the seller handover and dispute actions on a paid CONFIRMED order', () => {
    expect(availableOrderActions(order(), 'seller-1', now))
      .toEqual(['CANCEL', 'MARK_SHIPPED', 'OPEN_DISPUTE']);
  });

  it('returns the buyer receipt, delivery-confirmation and dispute actions on SHIPPED', () => {
    expect(availableOrderActions(order({ status: OrderStatus.SHIPPED }), 'buyer-1', now))
      .toEqual(['MARK_DELIVERED', 'CONFIRM_DELIVERY', 'OPEN_DISPUTE']);
  });

  it('keeps a resolved dispute visible without offering a transition', () => {
    expect(availableOrderActions(order({
      status: OrderStatus.COMPLETED,
      escrowStatus: EscrowStatus.RELEASED,
      dispute: { status: DisputeStatus.RESOLVED },
    }), 'buyer-1', now)).toEqual(['VIEW_DISPUTE']);
  });

  it('returns nothing for an outsider', () => {
    expect(availableOrderActions(order(), 'other', now)).toEqual([]);
  });
});
