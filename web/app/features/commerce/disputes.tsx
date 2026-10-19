import { Link } from 'react-router';
import { CommercePage, Empty, ErrorState, Loading, RequireAuth, Status, useCommerce, useCommerceQuery } from './shared';
import { commerceApi } from './api';
import { pathsFor } from '../../core/routes';

function DisputesContent() {
  const { t, locale, path } = useCommerce();
  const query = useCommerceQuery('disputes', [], (signal) => commerceApi.disputes(signal));
  return <CommercePage title={t('commerce.disputes.title')}>
    {query.isPending ? <Loading label={t('commerce.loading')}/> : query.isError ? <ErrorState error={query.error} onRetry={() => void query.refetch()}/> : query.data?.disputes.length ? <div className="commerce-list">{query.data.disputes.map((dispute) => <Link key={dispute.id} className="commerce-dispute-row" to={path(pathsFor.dispute(dispute.id))}><strong>{dispute.order.product.title}</strong><Status>{t(`commerce.disputeStatus.${dispute.status}`)}</Status><small>{new Date(dispute.createdAt).toLocaleDateString(locale)}</small><p>{dispute.reason}</p></Link>)}</div> : <Empty title={t('commerce.disputes.empty')}/>}
  </CommercePage>;
}
export default function DisputesPage() { return <RequireAuth><DisputesContent/></RequireAuth>; }
