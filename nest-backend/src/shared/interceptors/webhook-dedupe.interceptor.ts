import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from "@nestjs/common";
import { from, Observable, of, throwError } from "rxjs";
import { catchError, map, mergeMap } from "rxjs/operators";
import { StripeWebhookEvent } from "@/modules/payments/providers/stripe-provider";
import { RedisService } from "@/shared/infra/redis/redis.service";
import { Left, Either } from "@/shared/core/either";
import type { Failure } from "@/shared/core/errors";

type WebhookRequest = { stripeEvent?: StripeWebhookEvent };

const DEDUPE_TTL_SECONDS = 86400;

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

    if (!(await this.redis.setIfAbsent(key, "1", DEDUPE_TTL_SECONDS))) {
      this.logger.log(`Webhook ${eventId} already processed; skipping`);
      return of({ processed: false });
    }

    const releaseKey = () =>
      this.redis.del(key).catch((cleanupError: Error) => {
        this.logger.warn(
          `Failed to release webhook ${eventId} dedupe key: ${cleanupError.message}`,
        );
      });

    return next.handle().pipe(
      mergeMap((value) => {
        if (!(value instanceof Left)) return of(value);
        return from(releaseKey()).pipe(map(() => value));
      }),
      catchError((error: unknown) => {
        return from(releaseKey()).pipe(
          mergeMap(() => throwError(() => error)),
        );
      }),
    );
  }
}
