import { Logger } from '@nestjs/common';
import Stripe from 'stripe';

export type StripeWebhookEvent = Stripe.Event | Stripe.V2.Core.EventNotification;
export type VerifiedV2AccountWebhookEvent = Extract<
  Stripe.V2.Core.EventNotification,
  { related_object: { id: string; type: string } }
>;

export class StripeWebhookVerifier {
  constructor(
    private readonly stripe: Stripe,
    private readonly secret: string,
    private readonly logger: Logger,
  ) {}

  verify(payload: string, signature: string): boolean {
    return Boolean(signature && this.construct(payload, signature));
  }

  construct(payload: string, signature: string): StripeWebhookEvent | null {
    try {
      return this.stripe.webhooks.constructEvent(payload, signature, this.secret);
    } catch (v1Error) {
      try {
        return this.stripe.parseEventNotification(payload, signature, this.secret) ?? null;
      } catch (v2Error) {
        this.logger.warn(
          `Webhook signature verification failed: ${
            v2Error instanceof Error
              ? v2Error.message
              : v1Error instanceof Error
                ? v1Error.message
                : 'Unknown'
          }`,
        );
        return null;
      }
    }
  }
}
