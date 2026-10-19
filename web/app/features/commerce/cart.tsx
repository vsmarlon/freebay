import { useState } from 'react';
import { Link } from 'react-router';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { commerceApi } from './api';
import { Button, CommercePage, Dialog, Empty, ErrorState, Loading, RequireAuth, Surface, useCommerce, useCommerceQuery } from './shared';
import { userKey } from '../../core/query-client';
import { paths } from '../../core/routes';
import { Input } from '../../components';

function CartContent() {
  const { money, t, path, user } = useCommerce();
  const queryClient = useQueryClient();
  const [confirm, setConfirm] = useState<'clear' | string | null>(null);
  const cartQuery = useCommerceQuery('cart', [], commerceApi.cart);
  const productIds = cartQuery.data?.items.map((item) => item.productId) ?? [];
  const stockQuery = useCommerceQuery('cart-stock', productIds, async (signal) => {
    const items = await Promise.all(productIds.map(async (productId) => [productId, await commerceApi.productStock(productId, signal)] as const));
    return new Map(items);
  }, Boolean(cartQuery.data));
  const invalidate = () => queryClient.invalidateQueries({ queryKey: userKey(user?.id ?? '', 'commerce', 'cart') });
  const mutate = useMutation({ mutationFn: async (operation: { kind: 'clear' } | { kind: 'remove'; productId: string } | { kind: 'quantity'; productId: string; quantity: number }) => {
    if (operation.kind === 'clear') return commerceApi.clearCart();
    if (operation.kind === 'remove') return commerceApi.removeCartItem(operation.productId);
    return commerceApi.updateCartItem(operation.productId, operation.quantity);
  }, onSuccess: invalidate });
  const cart = cartQuery.data;
  return <CommercePage title={t('commerce.cart.title')}>
    {cartQuery.isPending ? <Loading label={t('commerce.cart.loading')}/> : cartQuery.isError ? <ErrorState error={cartQuery.error} onRetry={() => void cartQuery.refetch()}/> : !cart?.items.length ? <Empty title={t('commerce.cart.empty')}/> : <div className="commerce-columns">
      <div className="commerce-list">{cart.items.map((item) => {
        const product = stockQuery.data?.get(item.productId)?.product;
        const available = product ? (product.status === 'ACTIVE' ? Math.max(0, product.quantity - product.soldCount) : 0) : null;
        const max = Math.min(10, available ?? 10);
        return <Surface key={item.id} className="commerce-cart-item">
        <div><h2>{item.product.title}</h2><p>{t('commerce.cart.soldBy')} {item.product.seller.displayName}</p><strong>{money(item.subtotal)}</strong>{stockQuery.isSuccess && <p>{t('commerce.cart.available')}: {available}</p>}{available !== null && available < item.quantity && <p role="status">{t('commerce.cart.stockChanged')}</p>}</div>
        <div className="commerce-cart-controls"><Input id={`cart-quantity-${item.productId}`} label={t('commerce.cart.quantity')} type="number" min={1} max={Math.max(1, max)} value={item.quantity} disabled={mutate.isPending || stockQuery.isPending || stockQuery.isError || available === 0} onChange={(event) => { const quantity = Number(event.currentTarget.value); if (Number.isInteger(quantity) && quantity >= 1 && quantity <= max && quantity !== item.quantity) mutate.mutate({ kind: 'quantity', productId: item.productId, quantity }); }}/>
          <Button variant="ghost" disabled={mutate.isPending} onClick={() => setConfirm(item.productId)}>{t('commerce.cart.remove')}</Button></div>
      </Surface>; })}<Button variant="danger" disabled={mutate.isPending} onClick={() => setConfirm('clear')}>{t('commerce.cart.clear')}</Button></div>
      <Surface tone="mid" className="commerce-summary"><h2>{t('commerce.cart.summary')}</h2><p>{t('commerce.cart.items')} ({cart.totalItems})</p><strong>{money(cart.totalPrice)}</strong><p>{t('commerce.cart.canonical')}</p><Link className="ui-button ui-primary" to={path(paths.checkout)}>{t('commerce.cart.checkout')}</Link></Surface>
    </div>}
    {mutate.error && <ErrorState error={mutate.error}/>}
    {stockQuery.isError && <ErrorState error={stockQuery.error} onRetry={() => void stockQuery.refetch()}/>}
    <Dialog open={confirm !== null} onClose={() => setConfirm(null)} title={confirm === 'clear' ? t('commerce.cart.confirmClear') : t('commerce.cart.confirmRemove')} actions={<Button variant="danger" pending={mutate.isPending} onClick={() => { if (confirm === 'clear') mutate.mutate({ kind: 'clear' }); else if (confirm) mutate.mutate({ kind: 'remove', productId: confirm }); setConfirm(null); }}>{t('commerce.confirm')}</Button>}><p>{confirm === 'clear' ? t('commerce.cart.clear') : t('commerce.cart.remove')}</p></Dialog>
  </CommercePage>;
}
export default function CartPage() { return <RequireAuth><CartContent/></RequireAuth>; }
