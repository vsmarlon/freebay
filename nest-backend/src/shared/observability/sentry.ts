import { Logger } from '@nestjs/common';
import * as Sentry from '@sentry/node';

const logger = new Logger('Sentry');
let initialized = false;

export function initSentry(): void {
  const dsn = process.env.SENTRY_DSN;
  if (!dsn) return;

  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV ?? 'development',
    release: process.env.SENTRY_RELEASE,
    tracesSampleRate: 0,
    sendDefaultPii: false,
  });

  initialized = true;
  logger.log('Sentry initialized');
}

export function isSentryEnabled(): boolean {
  return initialized;
}

export function captureError(
  error: unknown,
  tags: Record<string, string | undefined>,
): void {
  if (!initialized) return;

  Sentry.withScope((scope) => {
    for (const [key, value] of Object.entries(tags)) {
      if (value) scope.setTag(key, value);
    }
    Sentry.captureException(error);
  });
}
