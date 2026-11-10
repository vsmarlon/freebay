import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { StepUpDialog } from '../auth';
import {
  Button,
  CommercePage,
  ErrorState,
  Loading,
  RequireAuth,
  Surface,
  useCommerce,
  useCommerceInfiniteQuery,
  useCommerceQuery,
} from './shared';
import { commerceApi } from './api';
import { safeConnectUrl } from './types';

function WalletContent() {
  const { locale, money, t } = useCommerce();
  const [stepUpOpen, setStepUpOpen] = useState(false);
  const walletQuery = useCommerceQuery('wallet', [], commerceApi.wallet);
  const connectQuery = useCommerceQuery('connect-status', [], commerceApi.connectStatus);
  const ledgerQuery = useCommerceInfiniteQuery('ledger', [], (cursor, signal) =>
    commerceApi.ledger(cursor, signal),
  );
  const ledgerItems = ledgerQuery.data?.pages.flatMap((page) => page.items) ?? [];
  const connect = useMutation<
    { onboardingUrl: string } | { dashboardUrl: string },
    Error,
    { kind: 'onboarding' | 'dashboard'; token?: string }
  >({
    mutationFn: ({ kind, token }) =>
      kind === 'onboarding'
        ? commerceApi.connectOnboarding()
        : commerceApi.connectDashboard(token ?? ''),
    onSuccess: (result) => {
      const raw = 'onboardingUrl' in result ? result.onboardingUrl : result.dashboardUrl;
      const url = safeConnectUrl(raw);
      if (!url) throw new Error(t('commerce.wallet.untrusted'));
      window.location.assign(url);
    },
  });
  const failure = walletQuery.error ?? connectQuery.error ?? ledgerQuery.error ?? connect.error;
  if (walletQuery.isPending || connectQuery.isPending || ledgerQuery.isPending)
    return (
      <CommercePage title={t('commerce.wallet.title')}>
        <Loading label={t('commerce.loading')} />
      </CommercePage>
    );
  return (
    <CommercePage title={t('commerce.wallet.title')}>
      {failure && (
        <ErrorState
          error={failure}
          onRetry={() => {
            void walletQuery.refetch();
            void connectQuery.refetch();
            void ledgerQuery.refetch();
          }}
        />
      )}
      {walletQuery.data && (
        <div className="grid grid-cols-3 gap-3 max-[760px]:grid-cols-1 [&_small]:text-muted [&_strong]:font-display [&_strong]:text-[22px] [&_strong]:font-bold">
          <Surface className="grid gap-2">
            <small>{t('commerce.wallet.total')}</small>
            <strong>{money(walletQuery.data.balance)}</strong>
          </Surface>
          <Surface className="grid gap-2">
            <small>{t('commerce.wallet.available')}</small>
            <strong>{money(walletQuery.data.availableBalance)}</strong>
          </Surface>
          <Surface className="grid gap-2">
            <small>{t('commerce.wallet.pending')}</small>
            <strong>{money(walletQuery.data.pendingBalance)}</strong>
          </Surface>
        </div>
      )}
      {connectQuery.data && (
        <Surface className="grid gap-[14px] bg-surface p-5 [&_ul]:my-0 [&_ul]:ps-5">
          <h2>{t('commerce.wallet.seller')}</h2>
          <p>
            {t('commerce.wallet.providerStatus')}:{' '}
            {t(`commerce.connect.${connectQuery.data.status}`)}
          </p>
          {connectQuery.data.requirementsDue.length > 0 && (
            <p className="wrap-break-word text-muted">{t('commerce.wallet.requirementsHint')}</p>
          )}
          <div className="flex flex-wrap items-center gap-[10px]">
            {connectQuery.data.status !== 'transfer-ready' && (
              <Button
                pending={connect.isPending}
                onClick={() => connect.mutate({ kind: 'onboarding' })}
              >
                {t('commerce.wallet.onboarding')}
              </Button>
            )}
            <Button
              variant="secondary"
              disabled={connect.isPending}
              onClick={() => setStepUpOpen(true)}
            >
              {t('commerce.wallet.dashboard')}
            </Button>
          </div>
        </Surface>
      )}
      <section className="grid gap-[10px] [&_h2]:m-0 [&_h2]:font-display [&_h2]:text-[22px] [&_h2]:font-bold">
        <h2>{t('commerce.wallet.ledger')}</h2>
        {ledgerItems.length ? (
          ledgerItems.map((entry) => (
            <Surface
              key={entry.id}
              className="flex items-center justify-between gap-[18px] bg-surface p-[18px] [&_small]:mt-1.5 [&_small]:block [&_small]:text-muted"
            >
              <span>
                <strong>{entry.productTitle ?? t(`commerce.wallet.reason.${entry.reason}`)}</strong>
                <small>
                  {t(`commerce.wallet.kind.${entry.kind}`)} ·{' '}
                  {new Date(entry.createdAt).toLocaleString(locale)}
                </small>
              </span>
              <strong>{money(entry.amount)}</strong>
            </Surface>
          ))
        ) : (
          <p>{t('commerce.empty')}</p>
        )}
        {ledgerQuery.hasNextPage && (
          <Button
            variant="secondary"
            disabled={ledgerQuery.isFetchingNextPage}
            onClick={() => void ledgerQuery.fetchNextPage()}
          >
            {ledgerQuery.isFetchingNextPage ? t('commerce.loading') : t('commerce.loadMore')}
          </Button>
        )}
      </section>
      <p>{t('commerce.wallet.depositsWithdrawals')}</p>
      <StepUpDialog
        open={stepUpOpen}
        action="connect_dashboard"
        onClose={() => setStepUpOpen(false)}
        onVerified={(token) => connect.mutate({ kind: 'dashboard', token })}
      />
    </CommercePage>
  );
}
export default function WalletPage() {
  return (
    <RequireAuth>
      <WalletContent />
    </RequireAuth>
  );
}
