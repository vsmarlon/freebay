import {
  applyDecorators,
  UseGuards,
  UseInterceptors,
  HttpCode,
  HttpStatus,
  Type,
  CanActivate,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { Public } from '@/shared/decorators/public.decorator';
import { WebhookGuard } from '@/shared/guards/webhook.guard';
import { WebhookDedupeInterceptor } from '@/shared/interceptors/webhook-dedupe.interceptor';
import { ApiDoc, ApiDocOptions } from '@/shared/swagger/api-doc.decorator';
import { ApiBearerAuth } from '@nestjs/swagger';

export interface ThrottleSpec {
  limit: number;
  ttl: number;
}

export type ThrottleConfig = ThrottleSpec | Record<string, ThrottleSpec>;

export interface EndpointOptions extends Omit<ApiDocOptions, 'auth'> {
  throttle?: ThrottleConfig;
  httpCode?: number;
}

export interface AuthenticatedOptions extends EndpointOptions {
  guards?: Type<CanActivate>[];
}

function normalizeThrottle(config: ThrottleConfig): Record<string, ThrottleSpec> {
  if (config && 'limit' in config && 'ttl' in config) {
    return { default: config as ThrottleSpec };
  }
  return config as Record<string, ThrottleSpec>;
}

function buildGuards(guards?: Type<CanActivate>[]): Array<ClassDecorator | MethodDecorator | PropertyDecorator> {
  const applied = guards ?? [JwtAuthGuard, NonGuestGuard];
  return [UseGuards(applied[0], ...applied.slice(1))];
}

export function Authenticated(opts: AuthenticatedOptions): MethodDecorator {
  const decorators: Array<ClassDecorator | MethodDecorator | PropertyDecorator> = [
    ...buildGuards(opts.guards),
    ApiBearerAuth(),
  ];

  if (opts.throttle) {
    decorators.push(Throttle(normalizeThrottle(opts.throttle)));
  }

  if (opts.httpCode !== undefined) {
    decorators.push(HttpCode(opts.httpCode));
  }

  decorators.push(ApiDoc({ ...opts, auth: true }));

  return applyDecorators(...decorators);
}

export const StripeWebhook = applyDecorators(
  Public(),
  Throttle({ default: { limit: 60, ttl: 60000 } }),
  UseGuards(WebhookGuard),
  UseInterceptors(WebhookDedupeInterceptor),
  HttpCode(HttpStatus.OK),
  ApiDoc({
    summary: 'Stripe webhook',
    description: 'Receives payment status updates from Stripe',
  }),
);

export function PublicEndpoint(opts: EndpointOptions): MethodDecorator {
  const decorators: Array<ClassDecorator | MethodDecorator | PropertyDecorator> = [Public()];

  if (opts.throttle) {
    decorators.push(Throttle(normalizeThrottle(opts.throttle)));
  }

  if (opts.httpCode !== undefined) {
    decorators.push(HttpCode(opts.httpCode));
  }

  decorators.push(ApiDoc(opts));

  return applyDecorators(...decorators);
}
