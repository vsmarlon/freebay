import {
  applyDecorators,
  UseGuards,
  UseInterceptors,
  HttpCode,
  HttpStatus,
  Type,
  CanActivate,
  Get,
  Post,
  Patch,
  Put,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from '@/shared/guards/roles.guard';
import { Public as SetPublicMetadata } from '@/shared/decorators/public.decorator';
import { Roles } from '@/shared/decorators/roles.decorator';
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
  roles?: string[];
}

export type AuthOptionsInput = string | AuthenticatedOptions;
export type PublicOptionsInput = string | EndpointOptions;

function normalizeThrottle(config: ThrottleConfig): Record<string, ThrottleSpec> {
  if (config && 'limit' in config && 'ttl' in config) {
    return { default: config as ThrottleSpec };
  }
  return config as Record<string, ThrottleSpec>;
}

function buildGuards(guards?: Type<CanActivate>[]): Array<ClassDecorator | MethodDecorator | PropertyDecorator> {
  const applied = guards ?? [JwtAuthGuard];
  return [UseGuards(applied[0], ...applied.slice(1))];
}

/**
 * Patternized authentication decorator.
 *
 * Overloads:
 * - `@Auth()` -> Applies JwtAuthGuard, BearerAuth, and default auth Swagger docs.
 * - `@Auth('Get user profile')` -> String summary shortcut without boilerplate objects.
 * - `@Auth({ summary: '...', roles: ['ADMIN'], ... })` -> Full options.
 */
export function Auth(input?: AuthOptionsInput): MethodDecorator {
  const opts: AuthenticatedOptions =
    typeof input === 'string' ? { summary: input } : (input ?? {});

  const decorators: Array<ClassDecorator | MethodDecorator | PropertyDecorator> = [
    ...buildGuards(opts.guards),
    ApiBearerAuth(),
  ];

  if (opts.roles && opts.roles.length > 0) {
    decorators.push(Roles(...opts.roles));
    decorators.push(UseGuards(RolesGuard));
  }

  if (opts.throttle) {
    decorators.push(Throttle(normalizeThrottle(opts.throttle)));
  }

  if (opts.httpCode !== undefined) {
    decorators.push(HttpCode(opts.httpCode));
  }

  const errors = [...(opts.errors ?? [])];
  if (opts.roles && opts.roles.length > 0 && !errors.some((e) => e.status === 403)) {
    errors.push({ status: 403, description: 'Forbidden: Insufficient permissions' });
  }

  decorators.push(ApiDoc({ ...opts, auth: true, errors }));

  return applyDecorators(...decorators);
}

/** Backward-compatible alias for @Auth */
export const Authenticated = Auth;

/**
 * Patternized admin-only route decorator.
 * Automatically enforces the 'ADMIN' role, attaches RolesGuard, BearerAuth, and 403 Swagger docs.
 *
 * Overloads:
 * - `@AdminOnly()`
 * - `@AdminOnly('Resolve dispute')`
 * - `@AdminOnly({ summary: '...', bodyType: ... })`
 */
export function AdminOnly(input?: AuthOptionsInput): MethodDecorator {
  const opts: AuthenticatedOptions =
    typeof input === 'string' ? { summary: input } : (input ?? {});
  return Auth({ ...opts, roles: ['ADMIN'] });
}

export const StripeWebhook = applyDecorators(
  SetPublicMetadata(),
  Throttle({ default: { limit: 60, ttl: 60000 } }),
  UseGuards(WebhookGuard),
  UseInterceptors(WebhookDedupeInterceptor),
  HttpCode(HttpStatus.OK),
  ApiDoc({
    summary: 'Stripe webhook',
    description: 'Receives payment status updates from Stripe',
  }),
);

/**
 * Patternized public endpoint decorator.
 *
 * Overloads:
 * - `@PublicEndpoint()`
 * - `@PublicEndpoint('List categories')`
 * - `@PublicEndpoint({ summary: '...', queries: [...] })`
 */
export function PublicEndpoint(input?: PublicOptionsInput): MethodDecorator {
  const opts: EndpointOptions =
    typeof input === 'string' ? { summary: input } : (input ?? {});

  const decorators: Array<ClassDecorator | MethodDecorator | PropertyDecorator> = [
    SetPublicMetadata(),
  ];

  if (opts.throttle) {
    decorators.push(Throttle(normalizeThrottle(opts.throttle)));
  }

  if (opts.httpCode !== undefined) {
    decorators.push(HttpCode(opts.httpCode));
  }

  if (opts.summary || opts.description || opts.queries || opts.params || opts.bodyType || opts.responseType || opts.errors) {
    decorators.push(ApiDoc(opts));
  }

  return applyDecorators(...decorators);
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSITE ROUTE DECORATORS (HTTP Method + Auth / Public / Admin + Swagger)
// ─────────────────────────────────────────────────────────────────────────────

function parseRouteArgs<T extends EndpointOptions>(
  arg1?: string | T,
  arg2?: string | T,
): { path?: string; options?: T } {
  if (typeof arg1 === 'string' && arg2 !== undefined) {
    const options = (typeof arg2 === 'string' ? { summary: arg2 } : arg2) as T;
    return { path: arg1, options };
  }
  if (typeof arg1 === 'string') {
    if (arg1.includes(' ')) {
      return { path: undefined, options: { summary: arg1 } as T };
    }
    return { path: arg1, options: undefined };
  }
  if (typeof arg1 === 'object' && arg1 !== null) {
    return { path: undefined, options: arg1 };
  }
  return { path: undefined, options: undefined };
}

// Authenticated Route Composites
export function GetAuth(pathOrOptions?: string | AuthOptionsInput, options?: AuthOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<AuthenticatedOptions>(pathOrOptions, options);
  return applyDecorators(Get(parsed.path), Auth(parsed.options));
}

export function PostAuth(pathOrOptions?: string | AuthOptionsInput, options?: AuthOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<AuthenticatedOptions>(pathOrOptions, options);
  return applyDecorators(Post(parsed.path), Auth(parsed.options));
}

export function PatchAuth(pathOrOptions?: string | AuthOptionsInput, options?: AuthOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<AuthenticatedOptions>(pathOrOptions, options);
  return applyDecorators(Patch(parsed.path), Auth(parsed.options));
}

export function PutAuth(pathOrOptions?: string | AuthOptionsInput, options?: AuthOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<AuthenticatedOptions>(pathOrOptions, options);
  return applyDecorators(Put(parsed.path), Auth(parsed.options));
}

// Public Route Composites
export function GetPublic(pathOrOptions?: string | PublicOptionsInput, options?: PublicOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<EndpointOptions>(pathOrOptions, options);
  return applyDecorators(Get(parsed.path), PublicEndpoint(parsed.options));
}

export function PostPublic(pathOrOptions?: string | PublicOptionsInput, options?: PublicOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<EndpointOptions>(pathOrOptions, options);
  return applyDecorators(Post(parsed.path), PublicEndpoint(parsed.options));
}

export function PatchPublic(pathOrOptions?: string | PublicOptionsInput, options?: PublicOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<EndpointOptions>(pathOrOptions, options);
  return applyDecorators(Patch(parsed.path), PublicEndpoint(parsed.options));
}

export function PutPublic(pathOrOptions?: string | PublicOptionsInput, options?: PublicOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<EndpointOptions>(pathOrOptions, options);
  return applyDecorators(Put(parsed.path), PublicEndpoint(parsed.options));
}

// Admin-Only Route Composites
export function GetAdmin(pathOrOptions?: string | AuthOptionsInput, options?: AuthOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<AuthenticatedOptions>(pathOrOptions, options);
  return applyDecorators(Get(parsed.path), AdminOnly(parsed.options));
}

export function PostAdmin(pathOrOptions?: string | AuthOptionsInput, options?: AuthOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<AuthenticatedOptions>(pathOrOptions, options);
  return applyDecorators(Post(parsed.path), AdminOnly(parsed.options));
}

export function PatchAdmin(pathOrOptions?: string | AuthOptionsInput, options?: AuthOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<AuthenticatedOptions>(pathOrOptions, options);
  return applyDecorators(Patch(parsed.path), AdminOnly(parsed.options));
}

export function PutAdmin(pathOrOptions?: string | AuthOptionsInput, options?: AuthOptionsInput): MethodDecorator {
  const parsed = parseRouteArgs<AuthenticatedOptions>(pathOrOptions, options);
  return applyDecorators(Put(parsed.path), AdminOnly(parsed.options));
}
