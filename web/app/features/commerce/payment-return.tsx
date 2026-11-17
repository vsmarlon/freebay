import { buttonClass } from '../../components';
import { Link, useLocation, useSearchParams } from 'react-router';
import {
  CommercePage,
  Empty,
  ErrorState,
  Loading,
  OrderRow,
  RequireAuth,
  useCommerce,
  useCommerceQuery,
} from './shared';
import { commerceApi } from './api';
import { paymentReturnState, type Order } from './types';
import { paths } from '../../core/routes';

// Settlement is webhook-authoritative, so this page can only re-read the server
// order state. PENDING is the one status still waiting for provider confirmation.
function awaitingSettlement(orders: Order[], groupId: string | null, orderId: string | null) {
  if (groupId)
    return orders.some(
      (order) => order.transaction?.paymentGroupId === groupId && order.status === 'PENDING',
    );
  if (orderId) return orders.some((order) => order.id === orderId && order.status === 'PENDING');
  return false;
}

function PaymentReturnContent() {
  const { pathname } = useLocation();
  const [params] = useSearchParams();
  const { t, path } = useCommerce();
  const groupId = params.get('paymentGroupId');
  const orderId = params.get('orderId');
  const cancelled = paymentReturnState(pathname) === 'cancelled';
  const query = useCommerceQuery(
    'payment-return-orders',
    [groupId, orderId],
    (signal) => commerceApi.purchases(null, signal, undefined, 50),
    true,
    (data) =>
      !cancelled && data && awaitingSettlement(data.items, groupId, orderId) ? 4000 : false,
  );
  const items = query.data?.items ?? [];
  const scopedOrders = groupId
    ? items.filter((order) => order.transaction?.paymentGroupId === groupId)
    : orderId
      ? items.filter((order) => order.id === orderId)
      : [];
  const visibleOrders = groupId || orderId ? scopedOrders : items;
  const emptyTitle =
    groupId || orderId ? t('commerce.paymentReturn.waitingOrders') : t('commerce.orders.empty');
  return (
    <CommercePage title={t('commerce.paymentReturn.title')}>
      <section className="grid gap-[14px] bg-surface p-5 [&_p]:max-w-[72ch] [&_h2]:m-0 [&_h2]:font-display [&_h2]:text-[22px] [&_h2]:font-bold">
        <h2>
          {cancelled ? t('commerce.paymentReturn.cancelled') : t('commerce.paymentReturn.pending')}
        </h2>
        <p>{t('commerce.paymentReturn.notice')}</p>
        {groupId && (
          <p>
            {t('commerce.paymentReturn.group')}: {groupId}
          </p>
        )}
      </section>
      {query.isPending ? (
        <Loading label={t('commerce.loading')} />
      ) : query.isError ? (
        <ErrorState error={query.error} onRetry={() => void query.refetch()} />
      ) : visibleOrders.length ? (
        <div className="grid gap-3">
          {visibleOrders.map((order) => (
            <OrderRow key={order.id} order={order} />
          ))}
        </div>
      ) : (
        <Empty title={emptyTitle} />
      )}
      <Link className={buttonClass('secondary')} to={path(paths.orders)}>
        {t('commerce.paymentReturn.orders')}
      </Link>
    </CommercePage>
  );
}
export default function PaymentReturnPage() {
  return (
    <RequireAuth>
      <PaymentReturnContent />
    </RequireAuth>
  );
}
