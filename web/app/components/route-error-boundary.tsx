import type { ReactNode } from 'react';
import { isRouteErrorResponse, useRouteError } from 'react-router';
import { useI18n, type Catalogs } from '../core/locale';
import { Button, ErrorState } from './index';
import { PageSection } from './page-section';

/** Which message a route error shows: the not-found copy for a route 404, else the fallback. */
export function routeErrorKey(
  error: unknown,
  notFoundKey: string | undefined,
  fallbackKey: string,
): string {
  return notFoundKey && isRouteErrorResponse(error) ? notFoundKey : fallbackKey;
}

/**
 * Route-level error boundary. Each route module keeps a named `ErrorBoundary`
 * export (React Router needs the name) that renders this with its own catalogs.
 */
export function RouteErrorBoundary({
  catalogs,
  notFoundKey,
  fallbackKey = 'common.error',
  showRetry = true,
  action,
}: {
  catalogs?: Catalogs;
  notFoundKey?: string;
  fallbackKey?: string;
  showRetry?: boolean;
  action?: ReactNode;
}) {
  const error = useRouteError();
  const { t } = useI18n(catalogs);
  return (
    <PageSection className="space-y-4">
      <ErrorState error={new Error(t(routeErrorKey(error, notFoundKey, fallbackKey)))} />
      {action}
      {showRetry ? (
        <Button variant="secondary" onClick={() => window.location.reload()}>
          {t('common.retry')}
        </Button>
      ) : null}
    </PageSection>
  );
}
