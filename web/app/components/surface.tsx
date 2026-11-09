import type { HTMLAttributes, ReactNode } from 'react';
import { useI18n } from '../core/locale';
import { Button } from './button';

export function Surface({
  tone = 'base',
  className = '',
  ...props
}: HTMLAttributes<HTMLDivElement> & { tone?: 'base' | 'mid' | 'high' }) {
  const bg = tone === 'base' ? 'bg-surface' : tone === 'mid' ? 'bg-surface-mid' : 'bg-surface-high';
  return <div {...props} className={`border border-(--hairline) p-4 ${bg} ${className}`} />;
}
export function PageHeader({
  title,
  description,
  actions,
}: {
  title: string;
  description?: string;
  actions?: ReactNode;
}) {
  return (
    <header className="flex items-center justify-between gap-5">
      <div>
        <h1 className="m-0 font-display text-[34px] font-bold">{title}</h1>
        {description ? <p>{description}</p> : null}
      </div>
      {actions ? <div className="flex flex-none items-center gap-2">{actions}</div> : null}
    </header>
  );
}
export function Status({
  children,
  tone = 'neutral',
}: {
  children: ReactNode;
  tone?: 'success' | 'warning' | 'error' | 'info' | 'neutral';
}) {
  const color =
    tone === 'success'
      ? 'text-success'
      : tone === 'warning'
        ? 'text-warning'
        : tone === 'error'
          ? 'text-danger'
          : tone === 'info'
            ? 'text-info'
            : '';
  return (
    <span className={`inline-flex bg-surface-mid px-2 py-1 text-[11px] font-bold ${color}`}>
      {children}
    </span>
  );
}
export function Loading({ label, rows = 3 }: { label?: string; rows?: number }) {
  const { t } = useI18n();
  return (
    <div role="status" aria-label={label ?? t('common.loading')} className="grid gap-3">
      {Array.from({ length: Math.max(1, rows) }, (_, i) => (
        <span
          key={i}
          className="h-14 animate-[shimmer_1000ms_linear_infinite_alternate] bg-surface-mid"
        />
      ))}
    </div>
  );
}
export function Empty({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <section className="border border-(--hairline) bg-surface p-8 text-center">
      <h2>{title}</h2>
      {description ? <p>{description}</p> : null}
      {action}
    </section>
  );
}
export function ErrorState({ error, onRetry }: { error: unknown; onRetry?: () => void }) {
  const { t } = useI18n();
  return (
    <section
      className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center"
      role="alert"
    >
      <p>{error instanceof Error ? error.message : t('common.error')}</p>
      {onRetry ? (
        <Button variant="secondary" onClick={onRetry}>
          {t('common.retry')}
        </Button>
      ) : null}
    </section>
  );
}
