import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { StepUpDialog } from '../auth';
import { Button, CommercePage, ErrorState, Loading, RequireAuth, Surface, useCommerce, useCommerceInfiniteQuery, useCommerceQuery } from './shared';
import { commerceApi } from './api';
import { safeConnectUrl } from './types';

function WalletContent() {
  const { locale, money, t } = useCommerce();
  const [stepUpOpen, setStepUpOpen] = useState(false);
  const walletQuery = useCommerceQuery('wallet', [], commerceApi.wallet);
  const connectQuery = useCommerceQuery('connect-status', [], commerceApi.connectStatus);
  const ledgerQuery = useCommerceInfiniteQuery('ledger', [], (cursor, signal) => commerceApi.ledger(cursor, signal));
  const ledgerItems = ledgerQuery.data?.pages.flatMap((page) => page.items) ?? [];
  const connect = useMutation<{ onboardingUrl: string } | { dashboardUrl: string }, Error, { kind: 'onboarding' | 'dashboard'; token?: string }>({ mutationFn: ({ kind, token }) => kind === 'onboarding' ? commerceApi.connectOnboarding() : commerceApi.connectDashboard(token ?? ''), onSuccess: (result) => {
    const raw = 'onboardingUrl' in result ? result.onboardingUrl : result.dashboardUrl;
    const url = safeConnectUrl(raw);
    if (!url) throw new Error(t('commerce.wallet.untrusted'));
    window.location.assign(url);
  } });
  const failure = walletQuery.error ?? connectQuery.error ?? ledgerQuery.error ?? connect.error;
  if (walletQuery.isPending || connectQuery.isPending || ledgerQuery.isPending) return <CommercePage title={t('commerce.wallet.title')}><Loading label={t('commerce.loading')}/></CommercePage>;
  return <CommercePage title={t('commerce.wallet.title')}>
    {failure && <ErrorState error={failure} onRetry={() => { void walletQuery.refetch(); void connectQuery.refetch(); void ledgerQuery.refetch(); }}/>}
    {walletQuery.data && <div className="commerce-balances"><Surface><small>{t('commerce.wallet.total')}</small><strong>{money(walletQuery.data.balance)}</strong></Surface><Surface><small>{t('commerce.wallet.available')}</small><strong>{money(walletQuery.data.availableBalance)}</strong></Surface><Surface><small>{t('commerce.wallet.pending')}</small><strong>{money(walletQuery.data.pendingBalance)}</strong></Surface></div>}
    {connectQuery.data && <Surface className="commerce-connect"><h2>{t('commerce.wallet.seller')}</h2><p>{t('commerce.wallet.providerStatus')}: {t(`commerce.connect.${connectQuery.data.status}`)}</p>{connectQuery.data.requirementsDue.length > 0 && <ul>{connectQuery.data.requirementsDue.map((requirement) => <li key={requirement}>{requirement}</li>)}</ul>}<div className="commerce-actions">{connectQuery.data.status !== 'transfer-ready' && <Button pending={connect.isPending} onClick={() => connect.mutate({ kind: 'onboarding' })}>{t('commerce.wallet.onboarding')}</Button>}<Button variant="secondary" disabled={connect.isPending} onClick={() => setStepUpOpen(true)}>{t('commerce.wallet.dashboard')}</Button></div></Surface>}
    <section className="commerce-ledger"><h2>{t('commerce.wallet.ledger')}</h2>{ledgerItems.length ? ledgerItems.map((entry) => <Surface key={entry.id} className="commerce-ledger-row"><span><strong>{entry.productTitle ?? t(`commerce.wallet.reason.${entry.reason}`)}</strong><small>{t(`commerce.wallet.kind.${entry.kind}`)} · {new Date(entry.createdAt).toLocaleString(locale)}</small></span><strong>{money(entry.amount)}</strong></Surface>) : <p>{t('commerce.empty')}</p>}{ledgerQuery.hasNextPage && <Button variant="secondary" disabled={ledgerQuery.isFetchingNextPage} onClick={() => void ledgerQuery.fetchNextPage()}>{ledgerQuery.isFetchingNextPage ? t('commerce.loading') : t('commerce.loadMore')}</Button>}</section>
    <p>{t('commerce.wallet.depositsWithdrawals')}</p>
    <StepUpDialog open={stepUpOpen} action="connect_dashboard" onClose={() => setStepUpOpen(false)} onVerified={(token) => connect.mutate({ kind: 'dashboard', token })} />
  </CommercePage>;
}
export default function WalletPage() { return <RequireAuth><WalletContent/></RequireAuth>; }
