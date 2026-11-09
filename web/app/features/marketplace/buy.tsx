import { useCallback, useEffect, useRef, useState } from 'react';
import { Link, useLoaderData, type LoaderFunctionArgs } from 'react-router';
import { ApiError } from '../../core/api';
import { Button, ErrorState, Icon, Loading, PageHeader, Surface, buttonClass } from '../../components';
import { useLocale, useI18n } from '../../core/locale';
import { useSession } from '../../core/session';
import { formatMoney } from '../../core/money';
import { paths, pathsFor } from '../../core/routes';
import { commerceApi } from '../commerce/api';
import type { Order } from '../commerce/types';
import { safeCheckoutUrl } from '../commerce/types';
import { getProduct } from './server.server';
import type { ProductSummary } from './types';
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';
import commerceEn from '../commerce/catalogs/en.json'; import commercePt from '../commerce/catalogs/pt-BR.json';

const catalogs = { en: { ...commerceEn, ...en }, 'pt-BR': { ...commercePt, ...pt } };
function attemptTimestamp() { return Date.now(); }
type LoaderData = { product: ProductSummary };
export async function loader({ params }: LoaderFunctionArgs): Promise<LoaderData> {
  if (!params.id) throw new Response('Not found', { status: 404 });
  return getProduct(params.id);
}

export default function BuyProductRoute() {
  const { product } = useLoaderData<LoaderData>();
  const { user, isPending } = useSession(); const { locale, path } = useLocale(); const { t } = useI18n(catalogs);
  const userId = user?.id ?? null;
  const userIdRef = useRef(userId);
  useEffect(() => { userIdRef.current = userId; }, [userId]);
  const [orderId, setOrderId] = useState<string | null>(null); const [busy, setBusy] = useState(false); const [restoring, setRestoring] = useState(true); const [storageUnavailable, setStorageUnavailable] = useState(false); const [error, setError] = useState<unknown>(null); const [uncertain, setUncertain] = useState(false); const [candidates, setCandidates] = useState<Order[]>([]);
  const attemptKey = user ? `freebay.direct-buy.${user.id}.${product.id}` : '';
  const mountRef = useCallback((node: HTMLDivElement | null) => {
    if (!node) return;
    if (isPending) return;
    if (!userId) { setRestoring(false); return; }
    let active = true;
    const controller = new AbortController();
    setRestoring(true); setOrderId(null); setUncertain(false); setCandidates([]); setStorageUnavailable(false);
    let attempt: unknown;
    try { attempt = JSON.parse(localStorage.getItem(attemptKey) ?? 'null'); } catch { setStorageUnavailable(true); setUncertain(true); setRestoring(false); return () => { active = false; controller.abort(); }; }
    if (attempt && typeof attempt === 'object' && 'orderId' in attempt && typeof attempt.orderId === 'string') {
      const savedId = attempt.orderId;
      void commerceApi.order(savedId, controller.signal).then((order) => {
        if (!active) return;
        if (order.buyerId !== userId || order.productId !== product.id) { setUncertain(true); return; }
        if (order.status === 'PENDING') setOrderId(order.id);
        else if (order.status === 'CANCELLED' || order.status === 'COMPLETED') localStorage.removeItem(attemptKey);
        else setUncertain(true);
      }).catch(() => { if (active) setUncertain(true); }).finally(() => { if (active) setRestoring(false); });
    } else if (attempt && typeof attempt === 'object' && 'state' in attempt && attempt.state === 'creating') {
      setUncertain(true); setRestoring(false);
    } else setRestoring(false);
    return () => { active = false; controller.abort(); };
  }, [attemptKey, isPending, product.id, userId]);
  const isOwner = user?.id === product.sellerId;
  async function begin() {
    if (!user || busy || uncertain || storageUnavailable || isOwner || product.status !== 'ACTIVE' || product.quantity <= product.soldCount) return;
    setBusy(true); setError(null);
    if (!orderId) {
      try { localStorage.setItem(attemptKey, JSON.stringify({ state: 'creating', productId: product.id, createdAt: attemptTimestamp() })); }
      catch (cause) { setStorageUnavailable(true); setError(cause); setBusy(false); return; }
    }
    try {
      let currentOrderId = orderId;
      if (!currentOrderId) {
        try { const order = await commerceApi.createOrder(product.id); currentOrderId = order.id; localStorage.setItem(attemptKey, JSON.stringify({ state: 'order', orderId: order.id, productId: product.id, createdAt: attemptTimestamp() })); }
        catch (cause) {
          if (cause instanceof ApiError && cause.status === 400 && cause.code === 'BAD_REQUEST' && ['Cannot buy your own product', 'Produto sem estoque', 'Produto não está mais disponível'].includes(cause.message)) {
            try { localStorage.removeItem(attemptKey); } catch { setStorageUnavailable(true); setUncertain(true); }
          } else setUncertain(true);
          throw cause;
        }
      }
      if (userIdRef.current !== user.id) return;
      setOrderId(currentOrderId);
      const session = await commerceApi.paymentSession(currentOrderId);
      const target = safeCheckoutUrl(session.checkoutUrl);
      if (!target) { setError(new Error(t('buy.badCheckoutUrl'))); return; }
      window.location.assign(target);
    } catch (cause) { setError(cause); }
    finally { setBusy(false); }
  }
  async function findPendingOrders() {
    if (!user || restoring || storageUnavailable) return;
    setRestoring(true); setError(null);
    try {
      const found: Order[] = [];
      let cursor: string | null = null;
      do {
        const page = await commerceApi.purchases(cursor);
        for (const row of page.items) {
          if (row.buyerId !== user.id || row.productId !== product.id || row.status !== 'PENDING') continue;
          const canonical = await commerceApi.order(row.id);
          if (canonical.buyerId === user.id && canonical.productId === product.id && canonical.status === 'PENDING') found.push(canonical);
        }
        cursor = page.nextCursor;
      } while (cursor);
      setCandidates(found);
    } catch (cause) { setError(cause); }
    finally { setRestoring(false); }
  }
  async function resumeKnownOrder(candidate: Order) {
    if (!user || candidate.buyerId !== user.id || candidate.productId !== product.id || candidate.status !== 'PENDING') return;
    setRestoring(true); setError(null);
    try {
      const canonical = await commerceApi.order(candidate.id);
      if (canonical.buyerId !== user.id || canonical.productId !== product.id || canonical.status !== 'PENDING') return;
      localStorage.setItem(attemptKey, JSON.stringify({ state: 'order', orderId: canonical.id, productId: product.id, createdAt: attemptTimestamp() }));
      setOrderId(canonical.id); setUncertain(false); setCandidates([]);
    } catch (cause) { setError(cause); }
    finally { setRestoring(false); }
  }
  if (isPending) return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><Loading label={t('common.loading')} /></section>;
  if (!user) return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><Surface><p>{t('auth.required')}</p><Link className={buttonClass('primary')} to={path(paths.login)}>{t('auth.signIn')}</Link></Surface></section>;
  return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5">
    <div ref={mountRef} className="sr-only" aria-hidden />
    <PageHeader title={t('buy.title')} />
    <Surface>
      <div className="flex items-start gap-4">
        {product.images[0]
          ? <img src={product.images[0].url} alt={t('product.imageAlt', { title: product.title, index: 1 })} className="size-24  shrink-0 object-cover" />
          : <div className="grid size-24  shrink-0 place-items-center bg-surface-mid text-muted"><Icon name="image" size={28} /></div>}
        <div className="grid gap-1">
          <h2>{product.title}</h2>
          <p className="text-muted">{t('buy.oneUnit')}</p>
          <strong className="text-lg">{formatMoney(product.price, locale)}</strong>
        </div>
      </div>
      {orderId && <p>{t('buy.orderCreated')}: <Link to={path(pathsFor.order(orderId))}>{orderId}</Link></p>}
      <p className="mt-3">{t('buy.quantityViaCart')} <Link className="inline-flex items-center gap-1.5 font-medium underline" to={path(paths.cart)}><Icon name="cart" size={16} />{t('commerce.cart.title')}</Link></p>
      {error !== null ? <ErrorState error={error instanceof Error ? error : new Error(String(error))} /> : null}
      {storageUnavailable && <p role="alert">{t('buy.storageUnavailable')}</p>}
      {uncertain && <div className="mt-3 bg-surface-mid p-3" role="alert">{t('buy.uncertain')}</div>}
      {candidates.map((candidate) => <div key={candidate.id}><p>{t('buy.orderCreated')}: <Link to={path(pathsFor.order(candidate.id))}>{candidate.id}</Link></p><Button variant="secondary" disabled={restoring} onClick={() => void resumeKnownOrder(candidate)}>{t('buy.resumeOrder')}</Button></div>)}
      <div className="mt-4 flex flex-wrap gap-2">
        {uncertain
          ? <Button variant="secondary" className="flex-1 justify-center" disabled={restoring || storageUnavailable} pending={restoring} onClick={() => void findPendingOrders()}>{t('buy.findPending')}</Button>
          : <Button className="flex-1 justify-center" disabled={busy || restoring || storageUnavailable || isOwner || product.status !== 'ACTIVE' || product.quantity <= product.soldCount} pending={busy || restoring} onClick={() => void begin()}>{orderId ? t('buy.retryPayment') : t('buy.continue')}</Button>}
        <Link className={`${buttonClass('secondary')} flex-1 justify-center text-center`} to={path(paths.orders)}>{t('commerce.orders.title')}</Link>
      </div>
    </Surface>
  </section>;
}
