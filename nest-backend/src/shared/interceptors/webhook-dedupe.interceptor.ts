import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import Stripe from 'stripe';
import { RedisService } from '@/shared/infra/redis/redis.service';

type WebhookRequest = { stripeEvent?: Stripe.Event };

const DEDUPE_TTL_SECONDS = 86400;

@Injectable()
export class WebhookDedupeInterceptor implements NestInterceptor {
  private readonly logger = new Logger(WebhookDedupeInterceptor.name);

  constructor(private readonly redis: RedisService) {}

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<unknown>> {
    const request = context.switchToHttp().getRequest<WebhookRequest>();
    const eventId = request.stripeEvent?.id;

    if (!eventId) {
      return next.handle();
    }

    const key = `webhook:${eventId}`;

    if (await this.redis.exists(key)) {
      this.logger.log(`Webhook ${eventId} already processed; skipping`);
      return of({ processed: false });
    }

    // Key is set only after the handler completes so a failed delivery never
    // poisons Stripe's retry with a false "already processed".
    return next.handle().pipe(
      tap(() => {
        this.redis.add(key, '1', DEDUPE_TTL_SECONDS).catch((error: Error) => {
          this.logger.warn(
            `Failed to record webhook ${eventId} as processed: ${error.message}`,
          );
        });
      }),
    );
  }
}
