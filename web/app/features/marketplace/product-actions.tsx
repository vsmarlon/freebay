import { useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { ApiError } from '../../core/api';
import { Button, ErrorState, Icon, buttonClass } from '../../components';
import { QuantityStepper } from '../../components/quantity-stepper';
import { useLocale } from '../../core/locale';
import { paths, pathsFor } from '../../core/routes';
import { useSession } from '../../core/session';
import { useProductActions } from './use-product-actions';
import type { ProductSummary } from './types';

const actionButton =
  'grid size-11 place-items-center border border-edge bg-transparent text-ink transition-colors duration-150 hover:enabled:bg-surface-mid focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2 disabled:cursor-not-allowed disabled:opacity-50';

export function ProductActions({ product, stock }: { product: ProductSummary; stock: number }) {
  const { path } = useLocale();
  const { user, isPending } = useSession();
  const navigate = useNavigate();
  const actions = useProductActions(product);
  const { t, favorite, follow, saved, following, busy, message } = actions;
  const [quantity, setQuantity] = useState('1');
  const maxCartQuantity = Math.min(10, stock);
  const selectedQuantity = Number(quantity);
  const quantityValid =
    Number.isSafeInteger(selectedQuantity) &&
    selectedQuantity >= 1 &&
    selectedQuantity <= maxCartQuantity;

  // A 401 from the favorite/follow probes is a signed-out viewer, not an action error.
  const redirectRef = (node: HTMLDivElement | null) => {
    if (!node) return;
    const failure = favorite.error ?? follow.error;
    if (failure instanceof ApiError && failure.status === 401) navigate(path(paths.login));
  };

  return (
    <section className="grid gap-3.5 border-b border-edge/25 py-4 last:border-b-0">
      <div ref={redirectRef} className="sr-only" aria-hidden />
      <div>
        <QuantityStepper
          label={t('product.quantity')}
          increase={t('product.increase')}
          decrease={t('product.decrease')}
          value={Math.max(1, Math.min(maxCartQuantity, Number(quantity) || 1))}
          max={maxCartQuantity}
          disabled={busy || isPending}
          onCommit={(next) => setQuantity(String(next))}
        />
      </div>
      <div className="grid grid-cols-[repeat(4,44px)] gap-2">
        <button
          type="button"
          className={actionButton}
          disabled={busy || isPending || !quantityValid}
          onClick={() => void actions.addToCart(selectedQuantity)}
          aria-label={t('product.addCart')}
          title={t('product.addCart')}
        >
          <Icon name="cart" size={20} />
        </button>
        <button
          type="button"
          className={`${actionButton}${saved ? ' bg-surface-mid text-brand' : ''}`}
          aria-label={saved ? t('product.unfavorite') : t('product.favorite')}
          aria-pressed={saved}
          disabled={busy || isPending || Boolean(user && (favorite.isPending || favorite.isError))}
          onClick={() => void actions.toggleFavorite()}
        >
          <Icon name="heart" size={20} />
        </button>
        <button
          type="button"
          className={actionButton}
          disabled={busy || isPending}
          onClick={() => void actions.contactSeller()}
          aria-label={t('product.contact')}
          title={t('product.contact')}
        >
          <Icon name="comment" size={20} />
        </button>
        <button
          type="button"
          className={`${actionButton}${following ? ' bg-surface-mid text-brand' : ''}`}
          disabled={busy || isPending || follow.isPending || follow.isError}
          aria-pressed={following}
          onClick={() => void actions.toggleFollow()}
          aria-label={following ? t('product.following') : t('product.follow')}
          title={following ? t('product.following') : t('product.follow')}
        >
          <Icon name={following ? 'unfollow' : 'follow'} size={20} />
        </button>
      </div>
      <Link className={buttonClass('primary')} to={path(`${pathsFor.product(product.id)}/buy`)}>
        {t('buy.continue')}
      </Link>
      {favorite.isError && (
        <>
          <ErrorState error={new Error(t('common.error'))} />
          <Button variant="ghost" onClick={() => void favorite.refetch()}>
            {t('common.retry')}
          </Button>
        </>
      )}
      {follow.isError && (
        <>
          <ErrorState error={new Error(t('common.error'))} />
          <Button variant="ghost" onClick={() => void follow.refetch()}>
            {t('common.retry')}
          </Button>
        </>
      )}
      {message && (
        <p role="status" className="m-0">
          {message}
        </p>
      )}
    </section>
  );
}
