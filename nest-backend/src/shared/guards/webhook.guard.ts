import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  Logger,
  RawBodyRequest,
} from '@nestjs/common';
import {
  StripeProvider,
  StripeWebhookEvent,
} from '@/modules/payments/providers/stripe-provider';
import { Request } from 'express';

type WebhookRequest = RawBodyRequest<Request> & {
  stripeEvent?: StripeWebhookEvent;
};

@Injectable()
export class WebhookGuard implements CanActivate {
  private readonly logger = new Logger(WebhookGuard.name);

  constructor(private readonly stripeProvider: StripeProvider) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<WebhookRequest>();
    const signature = request.headers['stripe-signature'] as string;
    const rawBody = request.rawBody?.toString() ?? '';

    const event = this.stripeProvider.constructWebhookEvent(rawBody, signature);
    if (!event) {
      this.logger.warn('Invalid Stripe webhook signature');
      throw new UnauthorizedException('Invalid signature');
    }

    request.stripeEvent = event;

    return true;
  }
}
