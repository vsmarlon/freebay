import { useState } from 'react';
import { Button, CommercePage, Empty, ErrorState, Loading, OrderRow, orderStatuses, RequireAuth, Select, useCommerce, useOrdersQuery } from './shared';
import type { OrderStatus } from './types';

const statuses: Array<'ALL' | OrderStatus> = ['ALL', ...orderStatuses];
function SalesContent() {
  const { t, status } = useCommerce();
  const [filter, setFilter] = useState<'ALL' | OrderStatus>('ALL');
  const query = useOrdersQuery('sales', filter);
  const items = query.data?.pages.flatMap((page) => page.items) ?? [];
  return <CommercePage title={t('commerce.sales.title')}>
    <Select label={t('commerce.statusFilter')} value={filter} onChange={(event) => setFilter(event.currentTarget.value as 'ALL' | OrderStatus)}>
      {statuses.map((value) => <option key={value} value={value}>{value === 'ALL' ? t('commerce.statusFilter.ALL') : status(value, 'commerce.status.')}</option>)}
    </Select>
    {query.isPending ? <Loading label={t('commerce.loading')}/> : query.isError ? <ErrorState error={query.error} onRetry={() => void query.refetch()}/> : items.length ? <div className="grid gap-3">{items.map((order) => <OrderRow key={order.id} order={order}/>)}</div> : <Empty title={t('commerce.sales.empty')}/>}
    {query.hasNextPage && <Button variant="secondary" disabled={query.isFetchingNextPage} onClick={() => void query.fetchNextPage()}>{query.isFetchingNextPage ? t('commerce.loading') : t('commerce.loadMore')}</Button>}
  </CommercePage>;
}
export default function SalesPage() { return <RequireAuth><SalesContent/></RequireAuth>; }
