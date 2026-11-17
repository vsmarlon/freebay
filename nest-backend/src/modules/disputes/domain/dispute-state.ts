// Mirrors the persisted DisputeStatus values: domain files must not import
// @prisma/client (ADR 0005, B5). Values are identical, so Prisma rows are accepted.
export const DISPUTE_STATUS = {
  OPEN: 'OPEN',
  AWAITING_SELLER: 'AWAITING_SELLER',
  AWAITING_BUYER: 'AWAITING_BUYER',
  ESCALATED: 'ESCALATED',
  RESOLVED: 'RESOLVED',
  CANCELLED: 'CANCELLED',
} as const;

export type DisputeStatus = (typeof DISPUTE_STATUS)[keyof typeof DISPUTE_STATUS];

/**
 * Active disputes freeze escrow, block automatic release, and block account
 * deletion. ESCALATED is active by design: escalation is visibility, not a
 * decision, and never moves money.
 */
export const ACTIVE_DISPUTE_STATUSES = [
  DISPUTE_STATUS.OPEN,
  DISPUTE_STATUS.AWAITING_SELLER,
  DISPUTE_STATUS.AWAITING_BUYER,
  DISPUTE_STATUS.ESCALATED,
] as const satisfies readonly DisputeStatus[];

export type ActiveDisputeStatus = (typeof ACTIVE_DISPUTE_STATUSES)[number];

/**
 * Active disputes that the escalation clock may still move. ESCALATED is
 * excluded so the cleanup task does not rewrite the same row every 30 minutes.
 */
export const ESCALATABLE_DISPUTE_STATUSES = [
  DISPUTE_STATUS.OPEN,
  DISPUTE_STATUS.AWAITING_SELLER,
  DISPUTE_STATUS.AWAITING_BUYER,
] as const satisfies readonly DisputeStatus[];

export type DisputeParty = 'BUYER' | 'SELLER';

export type DisputeAction = 'SUBMIT_EVIDENCE' | 'WITHDRAW' | 'REOPEN';

export function isActiveDisputeStatus(
  status: DisputeStatus,
): status is ActiveDisputeStatus {
  return ACTIVE_DISPUTE_STATUSES.some((active) => active === status);
}

export function partyOf(
  order: { buyerId: string; sellerId: string },
  userId: string,
): DisputeParty | null {
  if (order.buyerId === userId) return 'BUYER';
  if (order.sellerId === userId) return 'SELLER';
  return null;
}

/**
 * The party whose evidence the dispute is waiting for. `OPEN` waits for
 * nobody in particular: either participant may speak first.
 */
export function awaitedParty(status: DisputeStatus): DisputeParty | null {
  if (status === DISPUTE_STATUS.AWAITING_BUYER) return 'BUYER';
  if (status === DISPUTE_STATUS.AWAITING_SELLER) return 'SELLER';
  return null;
}

/**
 * The status a dispute moves to when `party` submits evidence, or null when
 * that party may not submit in the current status.
 */
export function evidenceTarget(
  status: DisputeStatus,
  party: DisputeParty,
): DisputeStatus | null {
  if (status === DISPUTE_STATUS.OPEN) {
    return party === 'BUYER'
      ? DISPUTE_STATUS.AWAITING_SELLER
      : DISPUTE_STATUS.AWAITING_BUYER;
  }
  const awaited = awaitedParty(status);
  if (awaited === null || awaited !== party) return null;
  return party === 'BUYER'
    ? DISPUTE_STATUS.AWAITING_SELLER
    : DISPUTE_STATUS.AWAITING_BUYER;
}

export function allowedDisputeActions(input: {
  status: DisputeStatus;
  party: DisputeParty | null;
  isOpener: boolean;
  canReopen: boolean;
}): DisputeAction[] {
  if (!input.party) return [];
  const actions: DisputeAction[] = [];
  if (evidenceTarget(input.status, input.party) !== null) {
    actions.push('SUBMIT_EVIDENCE');
  }
  if (isActiveDisputeStatus(input.status) && input.isOpener) {
    actions.push('WITHDRAW');
  }
  if (input.status === DISPUTE_STATUS.CANCELLED && input.isOpener && input.canReopen) {
    actions.push('REOPEN');
  }
  return actions;
}
