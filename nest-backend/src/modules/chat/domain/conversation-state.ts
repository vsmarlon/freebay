// Mirrors the persisted ConversationStatus values: domain files must not import
// @prisma/client (ADR 0005, B5). Values are identical, so Prisma rows are accepted.
export const CONVERSATION_STATUS = {
  PENDING: 'PENDING',
  ACTIVE: 'ACTIVE',
  BLOCKED: 'BLOCKED',
} as const;

export type ConversationStatus = (typeof CONVERSATION_STATUS)[keyof typeof CONVERSATION_STATUS];

/**
 * A direct conversation starts PENDING when the initiator is not followed by
 * the target. The initiator may send the opening message; the target may only
 * reply after accepting. `BLOCKED` is not a conversation transition — blocking
 * is enforced by the Block table — so a stale BLOCKED row cannot send.
 */
export function canSendDirect(input: {
  status: ConversationStatus;
  senderId: string;
  initiatorId: string | null;
}): boolean {
  if (input.status === CONVERSATION_STATUS.ACTIVE) return true;
  if (input.status !== CONVERSATION_STATUS.PENDING) return false;
  // Legacy rows predate initiatorId; allow them rather than locking an existing chat.
  return input.initiatorId === null || input.initiatorId === input.senderId;
}

export function canAcceptDirect(input: {
  status: ConversationStatus;
  userId: string;
  initiatorId: string | null;
}): boolean {
  if (input.status !== CONVERSATION_STATUS.PENDING) return false;
  return input.initiatorId === null || input.initiatorId !== input.userId;
}
