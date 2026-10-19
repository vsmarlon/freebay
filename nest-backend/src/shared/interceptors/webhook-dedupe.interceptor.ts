import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from "@nestjs/common";
import { from, Observable, of } from "rxjs";
import { map, mergeMap } from "rxjs/operators";
import { StripeWebhookEvent } from "@/modules/payments/providers/stripe-provider";
import { RedisService } from "@/shared/infra/redis/redis.service";
import { Either, Right } from "@/shared/core/either";
import type { Failure } from "@/shared/core/errors";

type WebhookRequest = { stripeEvent?: StripeWebhookEvent };

export const WEBHOOK_DEDUPE_TTL_SECONDS = 24 * 60 * 60;

@Injectable()
export class WebhookDedupeInterceptor implements NestInterceptor<
  Either<Failure, unknown>,
  Either<Failure, unknown> | { processed: boolean }
> {
  private readonly logger = new Logger(WebhookDedupeInterceptor.name);

  constructor(private readonly redis: RedisService) {}

  async intercept(
    context: ExecutionContext,
    next: CallHandler<Either<Failure, unknown>>,
  ): Promise<Observable<Either<Failure, unknown> | { processed: boolean }>> {
    const request = context.switchToHttp().getRequest<WebhookRequest>();
    const eventId = request.stripeEvent?.id;

    if (!eventId) {
      return next.handle();
    }

    const key = `webhook:${eventId}`;

    if (await this.redis.get(key)) {
      this.logger.log(`Webhook ${eventId} already processed; skipping`);
      return of({ processed: false });
    }

    return next.handle().pipe(
      mergeMap((value) => {
        if (!(value instanceof Right)) return of(value);
        return from(this.redis.add(key, "1", WEBHOOK_DEDUPE_TTL_SECONDS)).pipe(
          map(() => value),
        );
      }),
    );
  }
}
