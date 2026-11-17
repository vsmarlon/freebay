import { buttonClass } from '../../components';
import { useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { useMutation } from '@tanstack/react-query';
import {
  Button,
  CommercePage,
  Dialog,
  ErrorState,
  Loading,
  RequireAuth,
  Surface,
  TextArea,
  useCommerce,
  useCommerceQuery,
} from './shared';
import { commerceApi } from './api';
import { pathsFor } from '../../core/routes';

function OpenDisputeContent() {
  const { id, t, path } = useCommerce();
  const navigate = useNavigate();
  const [reason, setReason] = useState('');
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [uncertain, setUncertain] = useState(false);
  const orderQuery = useCommerceQuery(
    'order-for-dispute',
    [id],
    (signal) => commerceApi.orderWithActions(id, signal),
    Boolean(id),
  );
  const create = useMutation({
    mutationFn: () => commerceApi.openDispute(id, reason.trim()),
    onError: () => setUncertain(true),
    onSuccess: (result: { id: string }) => {
      void navigate(path(pathsFor.dispute(result.id)));
    },
  });
  if (orderQuery.isPending)
    return (
      <CommercePage title={t('commerce.dispute.open')}>
        <Loading label={t('commerce.loading')} />
      </CommercePage>
    );
  if (orderQuery.isError || !orderQuery.data)
    return (
      <CommercePage title={t('commerce.dispute.open')}>
        <ErrorState error={orderQuery.error} />
      </CommercePage>
    );
  const order = orderQuery.data.order;
  // Server-computed eligibility: OPEN_DISPUTE for a fresh dispute, REOPEN_DISPUTE
  // for a withdrawn one still inside the opening window. The backend also enforces
  // the window, cancellation reason and participant rules behind these actions.
  const allowedActions = orderQuery.data.allowedActions;
  const canOpen =
    allowedActions.includes('OPEN_DISPUTE') || allowedActions.includes('REOPEN_DISPUTE');
  return (
    <CommercePage title={t('commerce.dispute.open')}>
      <Surface>
        <p>
          {t('commerce.dispute.order')}: {order.product?.title ?? id}
        </p>
        {!canOpen ? (
          <p>{t('commerce.dispute.notAvailable')}</p>
        ) : (
          <form
            className="grid gap-4"
            onSubmit={(event) => {
              event.preventDefault();
              setConfirmOpen(true);
            }}
          >
            <p>{t('commerce.dispute.describe')}</p>
            <TextArea
              label={t('commerce.dispute.reason')}
              required
              value={reason}
              onChange={(event) => setReason(event.currentTarget.value)}
            />
            <Button disabled={!reason.trim() || create.isPending || uncertain}>
              {t('commerce.dispute.submit')}
            </Button>
          </form>
        )}
        {create.error && <ErrorState error={create.error} />}
        {uncertain && (
          <Link className={buttonClass('secondary')} to={path('disputes')}>
            {t('commerce.disputes.title')}
          </Link>
        )}
      </Surface>
      <Dialog
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        title={t('commerce.dispute.prompt')}
        actions={
          <Button
            pending={create.isPending}
            onClick={() => {
              setConfirmOpen(false);
              create.mutate();
            }}
          >
            {t('commerce.confirm')}
          </Button>
        }
      >
        <p>{reason}</p>
      </Dialog>
    </CommercePage>
  );
}
export default function OpenDisputePage() {
  return (
    <RequireAuth>
      <OpenDisputeContent />
    </RequireAuth>
  );
}
