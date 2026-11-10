import { buttonClass } from '../../components';
import { useState } from 'react';
import { Link } from 'react-router';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { commerceApi } from './api';
import {
  Button,
  CommercePage,
  Dialog,
  Empty,
  ErrorState,
  Loading,
  RequireAuth,
  Surface,
  useCommerce,
  useCommerceQuery,
} from './shared';
import { QuantityStepper } from '../../components/quantity-stepper';
import { userKey } from '../../core/query-client';
import { paths } from '../../core/routes';

function CartContent() {
  const { money, t, path, user } = useCommerce();
  const queryClient = useQueryClient();
  const [confirm, setConfirm] = useState<'clear' | string | null>(null);
  const cartQuery = useCommerceQuery('cart', [], commerceApi.cart);
  const productIds = cartQuery.data?.items.map((item) => item.productId) ?? [];
  const stockQuery = useCommerceQuery(
    'cart-stock',
    productIds,
    async (signal) => {
      const items = await Promise.all(
        productIds.map(
          async (productId) =>
            [productId, await commerceApi.productStock(productId, signal)] as const,
        ),
      );
      return new Map(items);
    },
    Boolean(cartQuery.data),
  );
  const invalidate = () =>
    queryClient.invalidateQueries({ queryKey: userKey(user?.id ?? '', 'commerce', 'cart') });
  const mutate = useMutation({
    mutationFn: async (
      operation:
        | { kind: 'clear' }
        | { kind: 'remove'; productId: string }
        | { kind: 'quantity'; productId: string; quantity: number },
    ) => {
      if (operation.kind === 'clear') return commerceApi.clearCart();
      if (operation.kind === 'remove') return commerceApi.removeCartItem(operation.productId);
      return commerceApi.updateCartItem(operation.productId, operation.quantity);
    },
    onSuccess: invalidate,
  });
  const cart = cartQuery.data;
  return (
    <CommercePage title={t('commerce.cart.title')}>
      {cartQuery.isPending ? (
        <Loading label={t('commerce.cart.loading')} />
      ) : cartQuery.isError ? (
        <ErrorState error={cartQuery.error} onRetry={() => void cartQuery.refetch()} />
      ) : !cart?.items.length ? (
        <Empty title={t('commerce.cart.empty')} />
      ) : (
        <div className="grid grid-cols-[minmax(0,1fr)_minmax(240px,320px)] items-start gap-5 max-[760px]:grid-cols-1">
          <div className="grid gap-3">
            {cart.items.map((item) => {
              const product = stockQuery.data?.get(item.productId)?.product;
              const available = product
                ? product.status === 'ACTIVE'
                  ? Math.max(0, product.quantity - product.soldCount)
                  : 0
                : null;
              const max = Math.min(10, available ?? 10);
              return (
                <Surface
                  key={item.id}
                  className="flex items-center justify-between gap-[18px] bg-surface p-[18px] max-[760px]:flex-col max-[760px]:items-stretch [&_h2]:mb-2 [&_h2]:mt-0 [&_h2]:font-display [&_h2]:text-[22px] [&_h2]:font-bold [&_p]:my-1 [&_p]:block [&_p]:text-muted"
                >
                  <div>
                    <h2>{item.product.title}</h2>
                    <p>
                      {t('commerce.cart.soldBy')} {item.product.seller.displayName}
                    </p>
                    <strong>{money(item.subtotal)}</strong>
                    {stockQuery.isSuccess && (
                      <p>
                        {t('commerce.cart.available')}: {available}
                      </p>
                    )}
                    {available !== null && available < item.quantity && (
                      <p role="status">{t('commerce.cart.stockChanged')}</p>
                    )}
                  </div>
                  <div className="flex items-end gap-2 max-[760px]:items-center max-[760px]:justify-between">
                    <QuantityStepper
                      label={t('commerce.cart.quantity')}
                      increase={t('commerce.cart.increase')}
                      decrease={t('commerce.cart.decrease')}
                      value={item.quantity}
                      max={Math.max(1, max)}
                      disabled={
                        mutate.isPending ||
                        stockQuery.isPending ||
                        stockQuery.isError ||
                        available === 0
                      }
                      onCommit={(quantity) =>
                        mutate.mutate({ kind: 'quantity', productId: item.productId, quantity })
                      }
                    />
                    <Button
                      variant="ghost"
                      disabled={mutate.isPending}
                      onClick={() => setConfirm(item.productId)}
                    >
                      {t('commerce.cart.remove')}
                    </Button>
                  </div>
                </Surface>
              );
            })}
            <Button
              variant="danger"
              disabled={mutate.isPending}
              onClick={() => setConfirm('clear')}
            >
              {t('commerce.cart.clear')}
            </Button>
          </div>
          <Surface
            tone="mid"
            className="grid gap-[14px] bg-surface-mid max-[760px]:order-first p-5 [&_h2]:m-0 [&_h2]:font-display [&_h2]:text-[22px] [&_h2]:font-bold [&_p]:max-w-[72ch]"
          >
            <h2>{t('commerce.cart.summary')}</h2>
            <p>
              {t('commerce.cart.items')} ({cart.totalItems})
            </p>
            <strong>{money(cart.totalPrice)}</strong>
            <p>{t('commerce.cart.canonical')}</p>
            <Link className={buttonClass('primary')} to={path(paths.checkout)}>
              {t('commerce.cart.checkout')}
            </Link>
          </Surface>
        </div>
      )}
      {mutate.error && <ErrorState error={mutate.error} />}
      {stockQuery.isError && (
        <ErrorState error={stockQuery.error} onRetry={() => void stockQuery.refetch()} />
      )}
      <Dialog
        open={confirm !== null}
        onClose={() => setConfirm(null)}
        title={
          confirm === 'clear' ? t('commerce.cart.confirmClear') : t('commerce.cart.confirmRemove')
        }
        actions={
          <Button
            variant="danger"
            pending={mutate.isPending}
            onClick={() => {
              if (confirm === 'clear') mutate.mutate({ kind: 'clear' });
              else if (confirm) mutate.mutate({ kind: 'remove', productId: confirm });
              setConfirm(null);
            }}
          >
            {t('commerce.confirm')}
          </Button>
        }
      >
        <p>{confirm === 'clear' ? t('commerce.cart.clear') : t('commerce.cart.remove')}</p>
      </Dialog>
    </CommercePage>
  );
}
export default function CartPage() {
  return (
    <RequireAuth>
      <CartContent />
    </RequireAuth>
  );
}
