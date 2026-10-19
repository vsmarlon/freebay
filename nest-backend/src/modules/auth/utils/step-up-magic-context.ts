import { createHmac, timingSafeEqual } from 'node:crypto';
import { isStepUpPurpose, type StepUpPurpose } from '@/shared/auth/biometric-credential.service';

export type StepUpMagicContext = {
  userId: string;
  purpose: string;
  resourceId?: string;
  tokenHash: string;
};

const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isValidStepUpResource(purpose: unknown, resourceId: unknown): purpose is StepUpPurpose {
  if (!isStepUpPurpose(purpose)) return false;
  return purpose === 'cancel_order'
    ? typeof resourceId === 'string' && UUID_V4.test(resourceId)
    : resourceId === undefined;
}

export function signStepUpMagicContext(secret: string, context: StepUpMagicContext): string {
  return createHmac('sha256', secret)
    .update(JSON.stringify([
      'freebay-web-step-up-v1',
      context.userId,
      context.purpose,
      context.resourceId ?? null,
      context.tokenHash,
    ]))
    .digest('hex');
}

export function verifyStepUpMagicContext(
  secret: string,
  context: StepUpMagicContext,
  signature: string,
): boolean {
  if (!/^[0-9a-f]{64}$/.test(signature)) return false;
  const actual = Buffer.from(signature, 'hex');
  const expected = Buffer.from(signStepUpMagicContext(secret, context), 'hex');
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}
