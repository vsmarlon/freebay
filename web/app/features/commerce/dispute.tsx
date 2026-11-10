import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Button,
  CommercePage,
  Dialog,
  ErrorState,
  RequireAuth,
  Status,
  Surface,
  TextArea,
  useCommerce,
  useCommerceQuery,
} from './shared';
import { commerceApi } from './api';
import { userKey } from '../../core/query-client';
import { canSubmitEvidence, canWithdrawDispute } from './types';

function DisputeContent() {
  const { id, user, locale, t } = useCommerce();
  const queryClient = useQueryClient();
  const [evidence, setEvidence] = useState('');
  const [withdrawOpen, setWithdrawOpen] = useState(false);
  const [reconcileNeeded, setReconcileNeeded] = useState(false);
  const query = useCommerceQuery(
    'dispute',
    [id],
    (signal) => commerceApi.dispute(id, signal),
    Boolean(id),
  );
  const dispute = query.data?.dispute;
  const isParty = Boolean(
    user && dispute && (user.id === dispute.order.buyerId || user.id === dispute.order.sellerId),
  );
  const evidenceMutation = useMutation({
    mutationFn: () => commerceApi.submitEvidence(id, evidence.trim()),
    onError: () => setReconcileNeeded(true),
    onSuccess: async () => {
      setReconcileNeeded(false);
      setEvidence('');
      await queryClient.invalidateQueries({
        queryKey: userKey(user?.id ?? '', 'commerce', 'dispute', id),
      });
    },
  });
  const withdrawMutation = useMutation({
    mutationFn: () => commerceApi.withdrawDispute(id),
    onError: () => setReconcileNeeded(true),
    onSuccess: async () => {
      setReconcileNeeded(false);
      await queryClient.invalidateQueries({
        queryKey: userKey(user?.id ?? '', 'commerce', 'dispute', id),
      });
      await queryClient.invalidateQueries({
        queryKey: userKey(user?.id ?? '', 'commerce', 'disputes'),
      });
    },
  });
  if (query.isPending)
    return (
      <CommercePage title={t('commerce.dispute.detail')}>
        <p role="status">{t('commerce.loading')}</p>
      </CommercePage>
    );
  if (query.isError || !dispute)
    return (
      <CommercePage title={t('commerce.dispute.detail')}>
        <ErrorState error={query.error} onRetry={() => void query.refetch()} />
      </CommercePage>
    );
  const myEvidence =
    user?.id === dispute.order.buyerId ? dispute.buyerEvidence : dispute.sellerEvidence;
  const otherEvidence =
    user?.id === dispute.order.buyerId ? dispute.sellerEvidence : dispute.buyerEvidence;
  const withdrawAllowed = canWithdrawDispute(dispute.status, dispute.openedById === user?.id);
  const formatEvidence = (value: unknown) =>
    typeof value === 'string' ? value : value == null ? '—' : JSON.stringify(value);
  return (
    <CommercePage title={t('commerce.dispute.detail')}>
      {(evidenceMutation.error || withdrawMutation.error) && (
        <>
          <ErrorState error={evidenceMutation.error ?? withdrawMutation.error} />
          <Button
            variant="secondary"
            onClick={() => {
              void query.refetch().then((result) => {
                if (!result.isError && result.data) {
                  evidenceMutation.reset();
                  withdrawMutation.reset();
                  setReconcileNeeded(false);
                }
              });
            }}
          >
            {t('commerce.order.reconcile')}
          </Button>
        </>
      )}
      <Surface className="grid gap-[14px] bg-surface p-5 [&_h2]:mb-2 [&_h2]:mt-0 [&_h2]:font-display [&_h2]:text-[22px] [&_h2]:font-bold">
        <h2>{dispute.order.product.title}</h2>
        <p>
          {t('commerce.status')}: <Status>{t(`commerce.disputeStatus.${dispute.status}`)}</Status>
        </p>
        <p>
          {t('commerce.dispute.reason')}: {dispute.reason}
        </p>
        <p>
          {t('commerce.dispute.opened')}: {new Date(dispute.createdAt).toLocaleString(locale)}
        </p>
        {dispute.resolution && (
          <p>
            {t('commerce.dispute.resolution')}: {dispute.resolution}
          </p>
        )}
      </Surface>
      <Surface
        tone="mid"
        className="grid gap-[14px] bg-surface p-5 [&_h2]:m-0 [&_h2]:font-display [&_h2]:text-[22px] [&_h2]:font-bold [&>p]:whitespace-pre-wrap [&>p]:wrap-break-word"
      >
        <h2>{t('commerce.dispute.evidence')}</h2>
        <p>
          {user?.id === dispute.order.buyerId
            ? t('commerce.dispute.buyer')
            : t('commerce.dispute.seller')}
          : {formatEvidence(myEvidence)}
        </p>
        <p>
          {user?.id === dispute.order.buyerId
            ? t('commerce.dispute.seller')
            : t('commerce.dispute.buyer')}
          : {formatEvidence(otherEvidence)}
        </p>
        {canSubmitEvidence(dispute.status, isParty) && (
          <form
            className="grid gap-4"
            onSubmit={(event) => {
              event.preventDefault();
              evidenceMutation.mutate();
            }}
          >
            <TextArea
              label={t('commerce.dispute.statement')}
              required
              value={evidence}
              onChange={(event) => setEvidence(event.currentTarget.value)}
            />
            <Button
              pending={evidenceMutation.isPending}
              disabled={reconcileNeeded || !evidence.trim()}
            >
              {t('commerce.dispute.submitEvidence')}
            </Button>
          </form>
        )}
        {withdrawAllowed && (
          <Button variant="danger" disabled={reconcileNeeded} onClick={() => setWithdrawOpen(true)}>
            {t('commerce.dispute.withdraw')}
          </Button>
        )}
      </Surface>
      <Dialog
        open={withdrawOpen}
        onClose={() => setWithdrawOpen(false)}
        title={t('commerce.dispute.withdrawPrompt')}
        actions={
          <Button
            variant="danger"
            pending={withdrawMutation.isPending}
            onClick={() => {
              setWithdrawOpen(false);
              withdrawMutation.mutate();
            }}
          >
            {t('commerce.confirm')}
          </Button>
        }
      >
        <p>{dispute.order.product.title}</p>
      </Dialog>
    </CommercePage>
  );
}
export default function DisputePage() {
  return (
    <RequireAuth>
      <DisputeContent />
    </RequireAuth>
  );
}
