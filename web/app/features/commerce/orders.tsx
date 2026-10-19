import { useState } from 'react';
import { Button, CommercePage, Empty, ErrorState, Loading, OrderRow, orderStatuses, RequireAuth, Select, useCommerce, useOrdersQuery } from './shared';
import type { OrderStatus } from './types';

function OrdersContent() {
  const { t, status } = useCommerce();
  const [cursor, setCursor] = useState<string | null>(null);
  const [filter, setFilter] = useState<'ALL' | OrderStatus>('ALL');
  const query = useOrdersQuery('purchases', cursor, filter);
  return <CommercePage title={t('commerce.orders.title')}>
    <Select label={t('commerce.statusFilter')} value={filter} onChange={(event) => { setFilter(event.currentTarget.value as 'ALL' | OrderStatus); setCursor(null); }}>
      <option value="ALL">{t('commerce.statusFilter.ALL')}</option>
      {orderStatuses.map((value) => <option key={value} value={value}>{status(value, 'commerce.status.')}</option>)}
    </Select>
    {query.isPending ? <Loading label={t('commerce.loading')}/> : query.isError ? <ErrorState error={query.error} onRetry={() => void query.refetch()}/> : query.data?.items.length ? <div className="commerce-list">{query.data.items.map((order) => <OrderRow key={order.id} order={order}/>)}</div> : <Empty title={t('commerce.orders.empty')}/>}
    {query.data?.hasMore && query.data.nextCursor && <Button variant="secondary" onClick={() => setCursor(query.data?.nextCursor ?? null)}>{t('commerce.loadMore')}</Button>}
  </CommercePage>;
}
export default function OrdersPage() { return <RequireAuth><OrdersContent/></RequireAuth>; }
