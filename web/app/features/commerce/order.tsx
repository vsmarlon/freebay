import { buttonClass } from '../../components';
import { useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { StepUpDialog } from '../auth';
import {
  Button,
  CommercePage,
  Dialog,
  ErrorState,
  Loading,
  RequireAuth,
  Status,
  Surface,
  TextArea,
  useCommerce,
  useCommerceQuery,
} from './shared';
import { commerceApi } from './api';
import { userKey } from '../../core/query-client';
import { pathsFor } from '../../core/routes';
import { orderParticipants, safeCheckoutUrl } from './types';

type ConfirmAction = 'ship' | 'deliver' | 'receipt' | 'cancel' | null;
function OrderContent() {
  const { id, user, locale, t, money, status, path } = useCommerce();
  const navigate = useNavigate();
  const [confirmAction, setConfirmAction] = useState<ConfirmAction>(null);
  const [stepUpOpen, setStepUpOpen] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [reconcileNeeded, setReconcileNeeded] = useState(false);
  const client = useQueryClient();
  const orderQuery = useCommerceQuery(
    'order',
    [id],
    (signal) => commerceApi.orderWithActions(id, signal),
    Boolean(id),
  );
  const order = orderQuery.data?.order;
  const allowedActions = orderQuery.data?.allowedActions ?? [];
  const actions = order && user ? orderParticipants(order, user.id) : null;
  const reviewEligibilityQuery = useCommerceQuery(
    'review-eligibility',
    [id],
    (signal) => commerceApi.reviewEligibility(id, signal),
    Boolean(order),
  );
  const conversationQuery = useCommerceQuery(
    'order-chat',
    [id],
    (signal) => commerceApi.orderConversation(id, signal),
    Boolean(order),
  );
  const buyerReviewsQuery = useCommerceQuery(
    'buyer-reviews',
    [order?.buyerId],
    (signal) =>
      order
        ? commerceApi.reviews(order.buyerId, signal)
        : Promise.resolve({ reviews: [], total: 0, offset: 0, limit: 50 }),
    Boolean(order),
  );
  const sellerReviewsQuery = useCommerceQuery(
    'seller-reviews',
    [order?.sellerId],
    (signal) =>
      order
        ? commerceApi.reviews(order.sellerId, signal)
        : Promise.resolve({ reviews: [], total: 0, offset: 0, limit: 50 }),
    Boolean(order),
  );
  const transition = useMutation({
    mutationFn: async ({
      action,
      token,
      reason,
    }: {
      action: Exclude<ConfirmAction, null>;
      token?: string;
      reason?: string;
    }) => {
      if (action === 'ship') return commerceApi.ship(id);
      if (action === 'deliver') return commerceApi.markDelivered(id);
      if (action === 'receipt') return commerceApi.confirmDelivery(id);
      if (!token || !reason?.trim() || reason.length > 500)
        throw new Error(t('commerce.order.cancelReason'));
      return commerceApi.cancel(id, reason.trim(), token);
    },
    onError: () => setReconcileNeeded(true),
    onSuccess: async () => {
      setReconcileNeeded(false);
      setStepUpOpen(false);
      setConfirmAction(null);
      await client.invalidateQueries({ queryKey: userKey(user?.id ?? '', 'commerce') });
    },
  });
  const resumePayment = useMutation({
    mutationFn: () => commerceApi.paymentSession(id),
    onSuccess: (session) => {
      const target = safeCheckoutUrl(session.checkoutUrl);
      if (target) window.location.assign(target);
      else throw new Error(t('commerce.checkout.missingUrl'));
    },
  });
  const startChat = useMutation({
    mutationFn: (targetUserId: string) => commerceApi.startConversation(targetUserId),
    onSuccess: (conversation) => navigate(path(pathsFor.conversation(conversation.conversationId))),
  });

  if (orderQuery.isPending)
    return (
      <CommercePage title={t('commerce.order.title')}>
        <Loading label={t('commerce.loading')} />
      </CommercePage>
    );
  if (orderQuery.isError || !order)
    return (
      <CommercePage title={t('commerce.order.title')}>
        <ErrorState error={orderQuery.error} onRetry={() => void orderQuery.refetch()} />
      </CommercePage>
    );
  const confirmText =
    confirmAction === 'ship'
      ? t('commerce.order.shipPrompt')
      : confirmAction === 'deliver'
        ? t('commerce.order.deliverPrompt')
        : confirmAction === 'receipt'
          ? t('commerce.order.confirmReceiptPrompt')
          : t('commerce.order.cancelPrompt');
  const participants = (
    <div className="grid gap-1 bg-surface-mid p-3">
      <p>
        {t('commerce.order.buyer')}: {order.buyer?.displayName ?? '—'}
      </p>
      <p>
        {t('commerce.order.seller')}: {order.seller?.displayName ?? '—'}
      </p>
    </div>
  );
  const reviews = (items: NonNullable<typeof buyerReviewsQuery.data>['reviews'], title: string) => (
    <Surface
      tone="mid"
      className="grid gap-3 [&_article]:grid [&_article]:gap-2 [&_article]:bg-surface [&_article]:p-3 [&_img]:h-[180px] [&_img]:w-full [&_img]:max-w-[180px] [&_img]:object-cover"
    >
      <h3>{title}</h3>
      {items.length ? (
        items.map((review) => (
          <article key={review.id}>
            <p>
              {review.score}/5 · {review.reviewer?.displayName ?? t('commerce.review.by')}
            </p>
            {review.comment && <p>{review.comment}</p>}
            {review.images?.map((image) => (
              <img key={image.id} src={image.url} alt="" loading="lazy" />
            ))}
          </article>
        ))
      ) : (
        <p>{t('commerce.review.empty')}</p>
      )}
    </Surface>
  );
  return (
    <CommercePage title={t('commerce.order.title')}>
      {transition.error && (
        <>
          <ErrorState error={transition.error} />
          <Button
            variant="secondary"
            onClick={() => {
              void orderQuery.refetch().then((result) => {
                if (!result.isError && result.data) {
                  transition.reset();
                  setReconcileNeeded(false);
                }
              });
            }}
          >
            {t('commerce.order.reconcile')}
          </Button>
        </>
      )}
      <div className="grid grid-cols-[minmax(0,1fr)_minmax(240px,320px)] items-start gap-5 max-[760px]:grid-cols-1">
        <Surface className="grid content-start gap-[14px] bg-surface p-5 [&_h2]:mb-2 [&_h2]:mt-0 [&_h2]:font-display [&_h2]:text-[22px] [&_h2]:font-bold">
          <p className="wrap-break-word text-muted">
            {t('commerce.order.reference')}: {order.id}
          </p>
          <h2>{order.product?.title ?? t('commerce.order.purchase')}</h2>
          <p>
            {t('commerce.status')}:{' '}
            <Status
              tone={
                order.status === 'COMPLETED'
                  ? 'success'
                  : order.status === 'DISPUTED' || order.status === 'CANCELLED'
                    ? 'error'
                    : order.status === 'PENDING'
                      ? 'warning'
                      : 'info'
              }
            >
              {status(order.status, 'commerce.status.')}
            </Status>
          </p>
          <p>
            {t('commerce.order.escrow')}:{' '}
            <Status
              tone={
                order.escrowStatus === 'RELEASED'
                  ? 'success'
                  : order.escrowStatus === 'REFUNDED'
                    ? 'error'
                    : 'warning'
              }
            >
              {status(order.escrowStatus, 'commerce.escrow.')}
            </Status>
          </p>
          <dl className="my-0 grid gap-2 [&_div]:flex [&_div]:justify-between [&_div]:gap-3 [&_dt]:text-muted [&_dd]:m-0 [&_dd]:font-bold">
            <div>
              <dt>{t('commerce.order.amount')}</dt>
              <dd>{money(order.amount)}</dd>
            </div>
            <div>
              <dt>{t('commerce.order.fee')}</dt>
              <dd>{money(order.platformFee)}</dd>
            </div>
            <div>
              <dt>{t('commerce.order.sellerAmount')}</dt>
              <dd>{money(order.sellerAmount)}</dd>
            </div>
          </dl>
          {participants}
          <div className="flex flex-wrap items-center gap-[10px]">
            {order.buyerId === user?.id &&
              order.status === 'PENDING' &&
              !order.transaction?.paymentGroupId && (
                <Button
                  pending={resumePayment.isPending}
                  disabled={resumePayment.isPending}
                  onClick={() => resumePayment.mutate()}
                >
                  {t('commerce.order.pay')}
                </Button>
              )}
            {allowedActions.includes('MARK_SHIPPED') && (
              <Button
                variant="secondary"
                disabled={reconcileNeeded}
                onClick={() => setConfirmAction('ship')}
              >
                {t('commerce.order.ship')}
              </Button>
            )}
            {allowedActions.includes('MARK_DELIVERED') && (
              <Button
                variant="secondary"
                disabled={reconcileNeeded}
                onClick={() => setConfirmAction('deliver')}
              >
                {t('commerce.order.deliver')}
              </Button>
            )}
            {allowedActions.includes('CONFIRM_DELIVERY') && (
              <Button disabled={reconcileNeeded} onClick={() => setConfirmAction('receipt')}>
                {t('commerce.order.confirmReceipt')}
              </Button>
            )}
            {allowedActions.includes('CANCEL') && (
              <Button
                variant="danger"
                disabled={reconcileNeeded}
                onClick={() => setConfirmAction('cancel')}
              >
                {t('commerce.order.cancel')}
              </Button>
            )}
            {(allowedActions.includes('OPEN_DISPUTE') ||
              allowedActions.includes('REOPEN_DISPUTE')) && (
              <Link className={buttonClass('secondary')} to={path(pathsFor.disputeOrder(id))}>
                {t('commerce.order.dispute')}
              </Link>
            )}
            {reviewEligibilityQuery.data?.canReview && reviewEligibilityQuery.data.reviewType && (
              <Link className={buttonClass('secondary')} to={path(pathsFor.reviewOrder(id))}>
                {reviewEligibilityQuery.data.reviewType === 'BUYER_REVIEWING_SELLER'
                  ? t('commerce.review.openSeller')
                  : t('commerce.review.open')}
              </Link>
            )}
            {conversationQuery.data ? (
              <Link
                className={buttonClass('secondary')}
                to={path(pathsFor.conversation(conversationQuery.data.id))}
              >
                {t('commerce.order.chat')}
              </Link>
            ) : (
              actions &&
              !conversationQuery.isPending && (
                <Button
                  variant="secondary"
                  pending={startChat.isPending}
                  onClick={() => startChat.mutate(actions.buyer ? order.sellerId : order.buyerId)}
                >
                  {t('commerce.order.chat')}
                </Button>
              )
            )}
          </div>
        </Surface>
        {resumePayment.error && <ErrorState error={resumePayment.error} />}
        <Surface
          tone="mid"
          className="grid gap-[14px] bg-surface p-5 [&_h2]:m-0 [&_h2]:font-display [&_h2]:text-[22px] [&_h2]:font-bold [&_p]:max-w-[72ch] [&_ol]:grid [&_ol]:gap-[10px] [&_ol]:py-0 [&_ol]:ps-5"
        >
          <h2>{t('commerce.order.timeline')}</h2>
          <ol>
            <li>
              {t('commerce.order.created')}: {new Date(order.createdAt).toLocaleString(locale)}
            </li>
            <li>
              {t('commerce.order.current')}: {status(order.status, 'commerce.status.')}
            </li>
            <li>
              {t('commerce.order.escrowState')}: {status(order.escrowStatus, 'commerce.escrow.')}
            </li>
          </ol>
          <p>{t('commerce.order.pendingWarning')}</p>
        </Surface>
      </div>
      {actions?.buyer &&
        reviews(sellerReviewsQuery.data?.reviews ?? [], t('commerce.review.seller'))}
      {actions?.seller &&
        reviews(buyerReviewsQuery.data?.reviews ?? [], t('commerce.review.buyer'))}
      {(buyerReviewsQuery.isError ||
        sellerReviewsQuery.isError ||
        conversationQuery.isError ||
        reviewEligibilityQuery.isError ||
        startChat.error) && (
        <ErrorState
          error={
            buyerReviewsQuery.error ??
            sellerReviewsQuery.error ??
            conversationQuery.error ??
            reviewEligibilityQuery.error ??
            startChat.error
          }
        />
      )}
      <Dialog
        open={confirmAction !== null}
        onClose={() => setConfirmAction(null)}
        title={confirmText}
        actions={
          <Button
            variant={confirmAction === 'cancel' ? 'danger' : 'primary'}
            pending={transition.isPending}
            disabled={
              reconcileNeeded ||
              (confirmAction === 'cancel' && (!cancelReason.trim() || cancelReason.length > 500))
            }
            onClick={() => {
              if (confirmAction === 'cancel') {
                if (!cancelReason.trim() || cancelReason.length > 500) return;
                setConfirmAction(null);
                setStepUpOpen(true);
                return;
              }
              if (confirmAction) transition.mutate({ action: confirmAction });
            }}
          >
            {t('commerce.confirm')}
          </Button>
        }
      >
        {confirmAction === 'cancel' && (
          <TextArea
            label={t('commerce.order.cancelReason')}
            maxLength={500}
            required
            value={cancelReason}
            onChange={(event) => setCancelReason(event.currentTarget.value)}
          />
        )}
      </Dialog>
      <StepUpDialog
        open={stepUpOpen}
        action="cancel_order"
        resourceId={id}
        onClose={() => setStepUpOpen(false)}
        onVerified={(token) => transition.mutate({ action: 'cancel', token, reason: cancelReason })}
      />
    </CommercePage>
  );
}
export default function OrderPage() {
  return (
    <RequireAuth>
      <OrderContent />
    </RequireAuth>
  );
}
