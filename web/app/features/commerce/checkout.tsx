import { useCallback, useRef, useState } from 'react';
import { Link } from 'react-router';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { ApiError } from '../../core/api';
import { userKey } from '../../core/query-client';
import { commerceApi } from './api';
import { Button, CommercePage, ErrorState, RequireAuth, Surface, useCommerce } from './shared';
import { canonicalCheckoutGroup, checkoutFailureIsDefinitive, safeCheckoutUrl } from './types';
import { paths, pathsFor } from '../../core/routes';

function CheckoutContent() {
  const { t, money, path, user } = useCommerce();
  const userIdRef = useRef(user?.id);
  userIdRef.current = user?.id;
  const queryClient = useQueryClient();
  const [ambiguous, setAmbiguous] = useState(false);
  const [rejected, setRejected] = useState(false);
  const [restoring, setRestoring] = useState(true);
  const [storageUnavailable, setStorageUnavailable] = useState(false);
  const [preflightError, setPreflightError] = useState<Error | null>(null);
  const [pendingOrderIds, setPendingOrderIds] = useState<string[]>([]);
  const [paidRecovery, setPaidRecovery] = useState(false);
  const attemptKey = user ? `freebay.cart-checkout.${user.id}` : '';
  function clearAttempt(key = attemptKey): boolean { try { localStorage.removeItem(key); return true; } catch { setStorageUnavailable(true); setAmbiguous(true); return false; } }
  const mountRef = useCallback((node: HTMLDivElement | null) => {
    if (!node) return;
    if (!user) { setRestoring(false); return; }
    let active = true;
    const controller = new AbortController();
     setRestoring(true); setPendingOrderIds([]); setStorageUnavailable(false); setPaidRecovery(false);
    void (async () => {
      try {
        const recovery = await commerceApi.checkoutRecovery(controller.signal);
        if (!active || userIdRef.current !== user.id) return;
        if (recovery) {
          setPendingOrderIds(recovery.orderIds);
          if (recovery.status === 'PAID') {
            setAmbiguous(false); setPaidRecovery(true);
            try {
              const saved: unknown = JSON.parse(localStorage.getItem(attemptKey) ?? 'null');
              if (saved && typeof saved === 'object' && 'paymentGroupId' in saved && saved.paymentGroupId === recovery.paymentGroupId) clearAttempt();
            } catch { setStorageUnavailable(true); }
            return;
          }
          setAmbiguous(true);
          const target = recovery.status === 'CHECKING' && recovery.checkoutUrl
            ? safeCheckoutUrl(recovery.checkoutUrl)
            : null;
          if (target) window.location.assign(target);
          return;
        }
        let attempt: unknown;
        try { attempt = JSON.parse(localStorage.getItem(attemptKey) ?? 'null'); }
        catch { setStorageUnavailable(true); setAmbiguous(true); return; }
        if (!attempt) { setAmbiguous(false); return; }
        setAmbiguous(true);
        const orderIds = attempt && typeof attempt === 'object' && 'orderIds' in attempt && Array.isArray(attempt.orderIds) && attempt.orderIds.every((id) => typeof id === 'string') ? attempt.orderIds : [];
        if (!orderIds.length) return;
        const orders = await Promise.all(orderIds.map((id) => commerceApi.order(id, controller.signal)));
        if (!active || orders.some((order) => order.buyerId !== user.id)) return;
        const pending = orders.filter((order) => order.status !== 'CANCELLED' && order.status !== 'COMPLETED');
        if (pending.length) setPendingOrderIds(pending.map((order) => order.id));
        else if (clearAttempt()) setAmbiguous(false);
      } catch {
        if (active) setAmbiguous(true);
      } finally {
        if (active) setRestoring(false);
      }
    })();
    return () => { active = false; controller.abort(); };
  }, [attemptKey, user?.id]);
  async function reconcilePendingOrders() {
    if (!user || storageUnavailable) return;
    setRestoring(true);
    try {
      const saved: unknown = JSON.parse(localStorage.getItem(attemptKey) ?? 'null');
      const productIds = saved && typeof saved === 'object' && 'productIds' in saved && Array.isArray(saved.productIds) && saved.productIds.every((id) => typeof id === 'string') ? saved.productIds : [];
      let cursor: string | null = null;
      const matching = new Map<string, string>();
      do {
        const page = await commerceApi.purchases(cursor);
        for (const order of page.items) if (order.buyerId === user.id && productIds.includes(order.productId)) matching.set(order.productId, order.id);
        cursor = page.nextCursor;
      } while (cursor);
      const canonical = await Promise.all([...matching.values()].map((id) => commerceApi.order(id)));
      if (canonical.some((order) => order.buyerId !== user.id || !productIds.includes(order.productId))) return;
      const activeOrders = canonical.filter((order) => order.status !== 'CANCELLED' && order.status !== 'COMPLETED');
      if (activeOrders.length) {
        const ids = activeOrders.map((order) => order.id);
        localStorage.setItem(attemptKey, JSON.stringify({ state: 'orders', productIds, orderIds: ids, createdAt: Date.now() }));
        setPendingOrderIds(ids);
      } else if (productIds.length && canonical.length === productIds.length) {
        if (clearAttempt()) setAmbiguous(false);
      }
    } catch { /* An unavailable or partial reconciliation never releases the hold. */ }
    finally { setRestoring(false); }
  }
  async function startCheckout() {
    if (!user || ambiguous || restoring || storageUnavailable || checkout.isPending) return;
    const buyerId = user.id;
    setRejected(false);
    setPreflightError(null);
    let productIds: string[];
    try {
      const cart = await commerceApi.cart();
      if (userIdRef.current !== buyerId) return;
      productIds = [...new Set(cart.items.map((item) => item.productId))];
      if (!productIds.length) { setPreflightError(new Error(t('commerce.checkout.cartEmpty'))); return; }
    } catch (cause) { setPreflightError(cause instanceof Error ? cause : new Error(String(cause))); return; }
    try { localStorage.setItem(attemptKey, JSON.stringify({ state: 'creating', productIds, createdAt: Date.now() })); }
    catch { setStorageUnavailable(true); return; }
    if (userIdRef.current !== buyerId) return;
    checkout.mutate({ key: attemptKey, buyerId });
  }
  const checkout = useMutation({ mutationFn: (attempt: { key: string; buyerId: string }) => {
    if (userIdRef.current !== attempt.buyerId) throw new Error('Session changed before checkout started');
    return commerceApi.checkout();
  }, onError: (error: unknown, attempt) => {
    const safelyRejected = error instanceof ApiError && checkoutFailureIsDefinitive(error.status, error.code, error.message);
    if (safelyRejected) {
      if (!clearAttempt(attempt.key)) return;
      if (userIdRef.current === attempt.buyerId) { setAmbiguous(false); setRejected(true); }
      void Promise.all([
        queryClient.invalidateQueries({ queryKey: userKey(attempt.buyerId, 'commerce', 'cart') }),
        queryClient.invalidateQueries({ queryKey: userKey(attempt.buyerId, 'commerce', 'cart-stock') }),
      ]);
    } else if (userIdRef.current === attempt.buyerId) setAmbiguous(true);
  }, onSuccess: (group, attempt) => {
    const orderIds = group.items.map((item) => item.orderId);
    try { localStorage.setItem(attempt.key, JSON.stringify({ state: 'orders', paymentGroupId: group.paymentGroupId, productIds: group.items.map((item) => item.productId), orderIds, createdAt: Date.now() })); }
    catch { if (userIdRef.current === attempt.buyerId) { setStorageUnavailable(true); setAmbiguous(true); } return; }
    if (userIdRef.current !== attempt.buyerId) return;
    setPendingOrderIds(orderIds);
    if (!group.checkoutUrl) { setAmbiguous(true); return; }
    const target = safeCheckoutUrl(group.checkoutUrl);
    if (!target) { setAmbiguous(true); return; }
    window.location.assign(target);
  } });
  const group = checkout.data ? canonicalCheckoutGroup(checkout.data) : undefined;
  return <CommercePage title={t('commerce.checkout.title')}><div ref={mountRef} className="sr-only" aria-hidden />
    <Surface className="commerce-checkout">
      <p>{t('commerce.checkout.explainer')}</p>
      {preflightError && <ErrorState error={preflightError} />}
      {paidRecovery && <Surface tone="mid"><p>{t('commerce.checkout.paymentConfirmed')}</p><Link className="ui-button ui-secondary" to={path(paths.orders)}>{t('commerce.orders.title')}</Link></Surface>}
      {storageUnavailable && <p role="alert">{t('commerce.checkout.storageUnavailable')}</p>}
      {group && <section className="commerce-summary" aria-live="polite"><h2>{t('commerce.checkout.total')}: {money(group.totalAmount)}</h2><p>{group.totalOrders} {t('commerce.checkout.orders')}</p>{group.items.map((item) => <p key={item.orderId}>{item.productTitle} × {item.quantity} — {money(item.amount)}</p>)}</section>}
      <Button disabled={checkout.isPending || ambiguous || restoring || storageUnavailable} pending={checkout.isPending || restoring} onClick={() => void startCheckout()}>{t('commerce.checkout.start')}</Button>
      {checkout.error != null ? <ErrorState error={checkout.error instanceof Error ? checkout.error : new Error(String(checkout.error))}/> : null}
      {rejected && <Surface tone="mid"><p>{t('commerce.checkout.rejected')}</p><Link className="ui-button ui-secondary" to={path(paths.cart)}>{t('commerce.checkout.reviewCart')}</Link></Surface>}
      {ambiguous && <Surface tone="mid"><p>{t('commerce.checkout.unclear')}</p><Link className="ui-button ui-secondary" to={path(paths.orders)}>{t('commerce.orders.title')}</Link><Button variant="secondary" disabled={restoring || storageUnavailable} pending={restoring} onClick={() => void reconcilePendingOrders()}>{t('commerce.checkout.reconcile')}</Button>{pendingOrderIds.map((id) => <Link key={id} to={path(pathsFor.order(id))}>{t('commerce.order.reference')}: {id}</Link>)}</Surface>}
    </Surface>
  </CommercePage>;
}
export default function CheckoutPage() { return <RequireAuth><CheckoutContent/></RequireAuth>; }
