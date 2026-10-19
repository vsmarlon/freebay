import { createHmac } from 'node:crypto';
import { isValidStepUpResource, signStepUpMagicContext, verifyStepUpMagicContext } from './step-up-magic-context';

describe('web step-up magic context', () => {
  const context = {
    userId: 'user-17', purpose: 'cancel_order', resourceId: '550e8400-e29b-41d4-a716-446655440000', tokenHash: 'ab'.repeat(32),
  };
  const secret = 'server-secret-never-sent-to-the-browser';

  it('signs the domain-separated canonical user/action/resource/token tuple', () => {
    const expected = createHmac('sha256', secret).update(JSON.stringify([
      'freebay-web-step-up-v1', context.userId, context.purpose, context.resourceId, context.tokenHash,
    ])).digest('hex');

    expect(signStepUpMagicContext(secret, context)).toBe(expected);
    expect(verifyStepUpMagicContext(secret, context, expected)).toBe(true);
  });

  it.each([
    ['another user', { ...context, userId: 'user-18' }],
    ['another action', { ...context, purpose: 'delete_account' }],
    ['another resource', { ...context, resourceId: '550e8400-e29b-41d4-a716-446655440001' }],
    ['another token', { ...context, tokenHash: 'cd'.repeat(32) }],
  ])('does not authorize %s with the original signature', (_label, changed) => {
    const signature = signStepUpMagicContext(secret, context);
    expect(verifyStepUpMagicContext(secret, changed, signature)).toBe(false);
  });

  it('rejects malformed signatures without comparing variable-length buffers', () => {
    expect(verifyStepUpMagicContext(secret, context, 'not-a-signature')).toBe(false);
    expect(verifyStepUpMagicContext(secret, context, 'A'.repeat(64))).toBe(false);
  });

  it('requires a UUID resource only for cancellation actions', () => {
    expect(isValidStepUpResource('cancel_order', context.resourceId)).toBe(true);
    expect(isValidStepUpResource('cancel_order', 'order-17')).toBe(false);
    expect(isValidStepUpResource('export_data', undefined)).toBe(true);
    expect(isValidStepUpResource('export_data', context.resourceId)).toBe(false);
  });
});
