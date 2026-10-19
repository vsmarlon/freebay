import type { ReactNode } from 'react';
import { Link, useParams } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { Button, Dialog, Empty, ErrorState, Input, Loading, PageHeader, Select, Surface, Status, TextArea } from '../../components';
import { useI18n } from '../../core/locale';
import { userKey } from '../../core/query-client';
import { RequireAuth, useSession } from '../../core/session';
import { formatMoney } from '../../core/money';
import { pathsFor } from '../../core/routes';
import { commerceApi } from './api';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import type { CursorPage, Order } from './types';
import './commerce.css';

const catalogs = { en, 'pt-BR': ptBR };
export { Button, Dialog, Empty, ErrorState, Input, Loading, RequireAuth, Select, Status, Surface, TextArea };
export { orderStatuses } from './types';
export type { Cart, CartItem, CheckoutGroup, ConnectStatus, CursorPage, Dispute, EscrowStatus, Order, OrderStatus, Review, ReviewEligibility, Wallet, WalletEntry } from './types';

export function useCommerce() {
  const { id = '' } = useParams();
  const { user } = useSession();
  const { locale, path, t } = useI18n(catalogs);
  const money = (cents: number) => formatMoney(cents, locale);
  const status = (value: string, prefix: 'commerce.status.' | 'commerce.escrow.') => t(`${prefix}${value}`) === `${prefix}${value}` ? t('commerce.unknown') : t(`${prefix}${value}`);
  return { id, user, locale, path, t, money, status };
}

export function useCommerceQuery<T>(feature: string, parts: readonly unknown[], queryFn: (signal: AbortSignal) => Promise<T>, enabled = true) {
  const { user } = useSession();
  return useQuery({
    queryKey: userKey(user?.id ?? 'anonymous', 'commerce', feature, ...parts),
    queryFn: ({ signal }) => queryFn(signal),
    enabled: enabled && Boolean(user?.id),
  });
}

export function CommercePage({ title, description, children, actions }: { title: string; description?: string; children: ReactNode; actions?: ReactNode }) {
  const { t, path } = useCommerce();
  return <main id="main-content" className="page-container"><PageHeader title={title} description={description} actions={actions}/><nav className="commerce-nav" aria-label={t('commerce.navigation')} style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem', marginTop: '1rem' }}><Link to={path(pathsFor.cart)}>{t('commerce.cart.title')}</Link><Link to={path(pathsFor.orders)}>{t('commerce.orders.title')}</Link><Link to={path(pathsFor.sales)}>{t('commerce.sales.title')}</Link><Link to={path(pathsFor.wallet)}>{t('commerce.wallet.title')}</Link><Link to={path(pathsFor.disputes)}>{t('commerce.disputes.title')}</Link></nav><div className="commerce-content">{children}</div></main>;
}

export function OrderRow({ order }: { order: Order }) {
  const { path, locale, money, status, t } = useCommerce();
  return <Link className="commerce-order-row" to={path(pathsFor.order(order.id))}>
    <span><strong>{order.product?.title ?? t('commerce.order.purchase')}</strong><small>{status(order.status, 'commerce.status.')} · {new Date(order.createdAt).toLocaleDateString(locale)}</small></span>
    <strong>{money(order.amount)}</strong>
  </Link>;
}

export function useOrdersQuery(feature: 'purchases' | 'sales', cursor: string | null, status?: string) {
  return useCommerceQuery<CursorPage<Order>>(feature, [cursor, status], (signal) => feature === 'purchases'
    ? commerceApi.purchases(cursor, signal, status)
    : commerceApi.sales(status, cursor, signal));
}
