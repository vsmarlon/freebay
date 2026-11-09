import { Link } from 'react-router';
import {
  CommercePage,
  Empty,
  ErrorState,
  Loading,
  RequireAuth,
  Status,
  useCommerce,
  useCommerceQuery,
} from './shared';
import { commerceApi } from './api';
import { pathsFor } from '../../core/routes';

function DisputesContent() {
  const { t, locale, path } = useCommerce();
  const query = useCommerceQuery('disputes', [], (signal) => commerceApi.disputes(signal));
  return (
    <CommercePage title={t('commerce.disputes.title')}>
      {query.isPending ? (
        <Loading label={t('commerce.loading')} />
      ) : query.isError ? (
        <ErrorState error={query.error} onRetry={() => void query.refetch()} />
      ) : query.data?.disputes.length ? (
        <div className="grid gap-3">
          {query.data.disputes.map((dispute) => (
            <Link
              key={dispute.id}
              className="grid gap-2 bg-surface p-[18px] text-ink hover:bg-surface-high focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-[3px] [&_p]:m-0 [&_p]:text-muted"
              to={path(pathsFor.dispute(dispute.id))}
            >
              <strong>{dispute.order.product.title}</strong>
              <Status>{t(`commerce.disputeStatus.${dispute.status}`)}</Status>
              <small>{new Date(dispute.createdAt).toLocaleDateString(locale)}</small>
              <p>{dispute.reason}</p>
            </Link>
          ))}
        </div>
      ) : (
        <Empty title={t('commerce.disputes.empty')} />
      )}
    </CommercePage>
  );
}
export default function DisputesPage() {
  return (
    <RequireAuth>
      <DisputesContent />
    </RequireAuth>
  );
}
