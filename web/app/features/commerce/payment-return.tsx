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
import { paymentReturnState } from './types';
import { paths } from '../../core/routes';

function PaymentReturnContent() {
  const { pathname } = useLocation();
  const [params] = useSearchParams();
  const { t, path } = useCommerce();
  const groupId = params.get('paymentGroupId');
  const query = useCommerceQuery('payment-return-orders', [groupId], (signal) =>
    commerceApi.purchases(null, signal, undefined, 50),
  );
  const cancelled = paymentReturnState(pathname) === 'cancelled';
  const groupOrders =
    query.data?.items.filter((order) => order.transaction?.paymentGroupId === groupId) ?? [];
  const visibleOrders = groupId ? groupOrders : (query.data?.items ?? []);
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
      ) : visibleOrders?.length ? (
        <div className="grid gap-3">
          {visibleOrders.map((order) => (
            <OrderRow key={order.id} order={order} />
          ))}
        </div>
      ) : (
        <Empty
          title={groupId ? t('commerce.paymentReturn.waitingOrders') : t('commerce.orders.empty')}
        />
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
