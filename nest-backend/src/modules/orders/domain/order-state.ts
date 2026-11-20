import { ACTIVE_DISPUTE_STATUSES, DISPUTE_STATUS, DisputeStatus } from '@/modules/disputes/domain/dispute-state';
import { DISPUTE_HOUR_IN_MILLISECONDS, DISPUTE_OPENING_WINDOW_HOURS } from '@/modules/disputes/dispute.constants';

// Mirrors the persisted enums: domain files must not import @prisma/client
// (ADR 0005, B5). Values are identical, so Prisma rows are accepted.
export const ORDER_STATUS = {
  PENDING: 'PENDING',
  CONFIRMED: 'CONFIRMED',
  SHIPPED: 'SHIPPED',
  DELIVERED: 'DELIVERED',
  DISPUTED: 'DISPUTED',
  REFUND_PENDING: 'REFUND_PENDING',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
} as const;

export type OrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS];

export const ESCROW_STATUS = {
  HELD: 'HELD',
  RELEASED: 'RELEASED',
  REFUNDED: 'REFUNDED',
} as const;

export type EscrowStatus = (typeof ESCROW_STATUS)[keyof typeof ESCROW_STATUS];

export const TRANSACTION_STATUS = {
  PENDING: 'PENDING',
  PROCESSING: 'PROCESSING',
  PAID: 'PAID',
  HELD: 'HELD',
  RELEASED: 'RELEASED',
  REFUNDED: 'REFUNDED',
  FAILED: 'FAILED',
} as const;

export type TransactionStatus = (typeof TRANSACTION_STATUS)[keyof typeof TRANSACTION_STATUS];

export const ORDER_ACTIONS = [
  'CANCEL',
  'MARK_SHIPPED',
  'MARK_DELIVERED',
  'CONFIRM_DELIVERY',
  'OPEN_DISPUTE',
  'REOPEN_DISPUTE',
  'VIEW_DISPUTE',
] as const;

export type OrderAction = (typeof ORDER_ACTIONS)[number];

export interface OrderParticipantView {
  status: OrderStatus;
  escrowStatus: EscrowStatus;
  cancellationReason: string | null;
  deliveryConfirmedAt: Date | null;
  createdAt: Date;
  buyerId: string;
  sellerId: string;
  dispute: { status: DisputeStatus } | null;
  transaction: {
    status: TransactionStatus;
    paymentGroupId: string | null;
    chargeId: string | null;
    externalId: string | null;
  } | null;
}

export function isOrderParticipant(order: { buyerId: string; sellerId: string }, userId: string): boolean {
  return order.buyerId === userId || order.sellerId === userId;
}

function hasCapturedPayment(order: OrderParticipantView): boolean {
  const status = order.transaction?.status;
  return status === TRANSACTION_STATUS.PAID || status === TRANSACTION_STATUS.HELD;
}

export function canCancelOrder(order: OrderParticipantView, viewerId: string): boolean {
  if (!isOrderParticipant(order, viewerId)) return false;
  if (order.status === ORDER_STATUS.PENDING) {
    const transaction = order.transaction;
    if (!transaction) return true;
    if (transaction.status !== TRANSACTION_STATUS.PENDING) return false;
    if (transaction.paymentGroupId) return false;
    return Boolean(transaction.externalId);
  }
  if (order.status === ORDER_STATUS.CONFIRMED) {
    const transaction = order.transaction;
    if (!transaction || !hasCapturedPayment(order)) return false;
    return Boolean(transaction.chargeId || transaction.externalId?.startsWith('pi_'));
  }
  return false;
}

export function canMarkShipped(order: OrderParticipantView, viewerId: string): boolean {
  return order.sellerId === viewerId
    && order.status === ORDER_STATUS.CONFIRMED
    && order.cancellationReason === null
    && hasCapturedPayment(order);
}

export function canMarkDelivered(order: OrderParticipantView, viewerId: string): boolean {
  return order.buyerId === viewerId
    && order.status === ORDER_STATUS.SHIPPED
    && order.cancellationReason === null
    && hasCapturedPayment(order);
}

export function canConfirmDelivery(order: OrderParticipantView, viewerId: string): boolean {
  return order.buyerId === viewerId
    && (order.status === ORDER_STATUS.CONFIRMED
      || order.status === ORDER_STATUS.SHIPPED
      || order.status === ORDER_STATUS.DELIVERED)
    && order.cancellationReason === null
    && order.escrowStatus === ESCROW_STATUS.HELD
    && hasCapturedPayment(order);
}

function isWithinDisputeOpeningWindow(order: OrderParticipantView, now: Date): boolean {
  if (order.status === ORDER_STATUS.SHIPPED) return true;
  const deliveryTime = order.deliveryConfirmedAt ?? order.createdAt;
  return (now.getTime() - deliveryTime.getTime()) <= DISPUTE_OPENING_WINDOW_HOURS * DISPUTE_HOUR_IN_MILLISECONDS;
}

function isDisputableOrder(order: OrderParticipantView): boolean {
  return order.status === ORDER_STATUS.CONFIRMED
    || order.status === ORDER_STATUS.SHIPPED
    || order.status === ORDER_STATUS.DELIVERED;
}

export function canOpenDispute(order: OrderParticipantView, viewerId: string, now: Date): boolean {
  return isOrderParticipant(order, viewerId)
    && isDisputableOrder(order)
    && order.dispute === null
    && order.cancellationReason === null
    && isWithinDisputeOpeningWindow(order, now);
}

export function canReopenDispute(order: OrderParticipantView, viewerId: string, now: Date): boolean {
  return isOrderParticipant(order, viewerId)
    && isDisputableOrder(order)
    && order.dispute?.status === DISPUTE_STATUS.CANCELLED
    && order.cancellationReason === null
    && isWithinDisputeOpeningWindow(order, now);
}

export function hasActiveDispute(order: OrderParticipantView): boolean {
  return order.dispute !== null
    && ACTIVE_DISPUTE_STATUSES.some((status) => status === order.dispute!.status);
}

/**
 * The actions a participant may take right now. This is the same predicate set
 * the write use cases use, so the API cannot offer an action the backend will
 * reject. Keep new guards here, not in a controller or a client.
 */
export function availableOrderActions(
  order: OrderParticipantView,
  viewerId: string,
  now: Date = new Date(),
): OrderAction[] {
  if (!isOrderParticipant(order, viewerId)) return [];
  const actions: OrderAction[] = [];
  if (canCancelOrder(order, viewerId)) actions.push('CANCEL');
  if (canMarkShipped(order, viewerId)) actions.push('MARK_SHIPPED');
  if (canMarkDelivered(order, viewerId)) actions.push('MARK_DELIVERED');
  if (canConfirmDelivery(order, viewerId)) actions.push('CONFIRM_DELIVERY');
  if (canOpenDispute(order, viewerId, now)) actions.push('OPEN_DISPUTE');
  if (canReopenDispute(order, viewerId, now)) actions.push('REOPEN_DISPUTE');
  if (order.dispute && order.dispute.status !== DISPUTE_STATUS.CANCELLED) actions.push('VIEW_DISPUTE');
  return actions;
}
