import { ConversationStatus } from '@prisma/client';
import { canAcceptDirect, canSendDirect } from './conversation-state';

describe('direct conversation state', () => {
  it('lets the initiator open a PENDING conversation but not the target', () => {
    const pending = { status: ConversationStatus.PENDING, initiatorId: 'initiator-1' };
    expect(canSendDirect({ ...pending, senderId: 'initiator-1' })).toBe(true);
    expect(canSendDirect({ ...pending, senderId: 'target-1' })).toBe(false);
  });

  it('allows both participants once the conversation is ACTIVE', () => {
    const active = { status: ConversationStatus.ACTIVE, initiatorId: 'initiator-1' };
    expect(canSendDirect({ ...active, senderId: 'initiator-1' })).toBe(true);
    expect(canSendDirect({ ...active, senderId: 'target-1' })).toBe(true);
  });

  it('does not send in a BLOCKED or otherwise terminal conversation', () => {
    expect(canSendDirect({
      status: ConversationStatus.BLOCKED,
      initiatorId: 'initiator-1',
      senderId: 'initiator-1',
    })).toBe(false);
  });

  it('keeps legacy PENDING rows without an initiator usable', () => {
    expect(canSendDirect({
      status: ConversationStatus.PENDING,
      initiatorId: null,
      senderId: 'either-1',
    })).toBe(true);
  });

  it('only the non-initiator accepts a PENDING conversation', () => {
    const pending = { status: ConversationStatus.PENDING, initiatorId: 'initiator-1' };
    expect(canAcceptDirect({ ...pending, userId: 'target-1' })).toBe(true);
    expect(canAcceptDirect({ ...pending, userId: 'initiator-1' })).toBe(false);
    expect(canAcceptDirect({ status: ConversationStatus.ACTIVE, userId: 'target-1', initiatorId: 'initiator-1' })).toBe(false);
  });

  it('accepts a legacy PENDING row from either participant', () => {
    expect(canAcceptDirect({ status: ConversationStatus.PENDING, userId: 'either-1', initiatorId: null })).toBe(true);
  });
});
