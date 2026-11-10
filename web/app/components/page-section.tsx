import type { ComponentProps } from 'react';

/** Page shell used by every route: centred, capped at 80rem, mobile gutters. */
export function PageSection({ className = '', ...props }: ComponentProps<'section'>) {
  return <section className={`page-section ${className}`} {...props} />;
}
