import { useCallback, useState } from 'react';
import {
  Link,
  useLoaderData,
  useNavigate,
  useRouteError,
  isRouteErrorResponse,
  type LoaderFunctionArgs,
  type MetaFunction,
} from 'react-router';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ApiError, api } from '../../core/api';
import {
  Avatar,
  Button,
  ErrorState,
  Icon,
  Loading,
  PageHeader,
  Status,
  Surface,
  buttonClass,
} from '../../components';
import { ImageCarousel } from './image-carousel';
import { QuantityStepper } from '../../components/quantity-stepper';
import { useSession } from '../../core/session';
import { useLocale, useI18n } from '../../core/locale';
import { paths, pathsFor } from '../../core/routes';
import { formatMoney } from '../../core/money';
import { userKey } from '../../core/query-client';
import { mediaUrl } from '../../core/media';
import { productInquiryDraftState } from './product-inquiry-draft';
import type { ProductSummary } from './types';
import { getProduct } from './server.server';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };
type LoaderData = { product: ProductSummary };
export async function loader({ params }: LoaderFunctionArgs): Promise<LoaderData> {
  if (!params.id) throw new Response('Not found', { status: 404 });
  return getProduct(params.id);
}
export const meta: MetaFunction<typeof loader> = ({ data }) =>
  data?.product
    ? [
        { title: `${data.product.title} — Freebay` },
        { name: 'description', content: data.product.description.slice(0, 160) },
        { property: 'og:title', content: `${data.product.title} — Freebay` },
        { property: 'og:description', content: data.product.description.slice(0, 200) },
        ...(data.product.images[0]
          ? [{ property: 'og:image', content: data.product.images[0].url }]
          : []),
      ]
    : [{ title: 'Freebay' }];

type Favorite = { isFavorited: boolean };
type Conversation = { conversationId: string };
type FollowStatus = { isFollowing: boolean; followersCount: number; followingCount: number };
type SellerProfile = { reputationScore: number; totalReviews: number };
type ReviewList = {
  reviews: Array<{
    id: string;
    score: number;
    comment: string | null;
    reviewer: { displayName: string };
  }>;
  total: number;
  offset: number;
  limit: number;
};
function listingStatusTone(
  status: ProductSummary['status'],
): 'success' | 'warning' | 'error' | 'info' | 'neutral' {
  if (status === 'ACTIVE') return 'success';
  if (status === 'PAUSED') return 'warning';
  if (status === 'SOLD') return 'info';
  return 'neutral';
}

export default function ProductDetailRoute() {
  const { product } = useLoaderData<LoaderData>();
  const { locale, path } = useLocale();
  const { t } = useI18n(catalogs);
  const { user, isPending } = useSession();
  const cache = useQueryClient();
  const navigate = useNavigate();
  const [quantity, setQuantity] = useState('1');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');
  const isOwner = user?.id === product.sellerId;
  const stock = Math.max(0, product.quantity - product.soldCount);
  const maxCartQuantity = Math.min(10, stock);
  const selectedQuantity = Number(quantity);
  const quantityValid =
    Number.isSafeInteger(selectedQuantity) &&
    selectedQuantity >= 1 &&
    selectedQuantity <= maxCartQuantity;
  const canBuy = product.status === 'ACTIVE' && stock > 0 && !isOwner;
  const favoriteKey = user
    ? userKey(user.id, 'favorites', product.id)
    : ['anonymous', 'favorite', product.id];
  const favorite = useQuery({
    queryKey: favoriteKey,
    enabled: Boolean(user) && !isOwner,
    queryFn: () => api.get<Favorite>(`/favorites/check/${product.id}`),
  });
  const followKey = user
    ? userKey(user.id, 'follow', product.sellerId)
    : ['anonymous', 'follow', product.sellerId];
  const follow = useQuery({
    queryKey: followKey,
    enabled: Boolean(user) && !isOwner,
    queryFn: () => api.get<FollowStatus>(`/users/${product.sellerId}/is-following`),
  });
  const seller = useQuery({
    queryKey: ['public', 'seller', product.sellerId],
    queryFn: () => api.get<SellerProfile>(`/users/${product.sellerId}`, { auth: false }),
  });
  const reviews = useQuery({
    queryKey: ['public', 'reviews', product.sellerId],
    queryFn: () =>
      api.get<ReviewList>(`/reviews/users/${product.sellerId}?limit=5`, { auth: false }),
  });
  const saved = favorite.data?.isFavorited === true;
  const redirectRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (!node) return;
      const failure = favorite.error ?? follow.error;
      if (failure instanceof ApiError && failure.status === 401) navigate(path(paths.login));
    },
    [favorite.error, follow.error, navigate, path],
  );

  function requireLogin() {
    navigate(path(paths.login));
  }
  function handleMutationError(cause: unknown, fallback: string) {
    if (cause instanceof ApiError && cause.status === 401) requireLogin();
    else setMessage(fallback);
  }
  async function toggleFavorite() {
    if (!user) return requireLogin();
    setBusy(true);
    setMessage('');
    try {
      await api.post(`/favorites/${product.id}`);
      await cache.invalidateQueries({ queryKey: favoriteKey });
      await cache.invalidateQueries({ queryKey: userKey(user.id, 'favorites') });
    } catch (cause) {
      handleMutationError(cause, t('common.error'));
    } finally {
      setBusy(false);
    }
  }
  async function addToCart() {
    if (!user) return requireLogin();
    setBusy(true);
    setMessage('');
    try {
      await api.post(`/cart/${product.id}`, { quantity: selectedQuantity });
      await cache.invalidateQueries({ queryKey: userKey(user.id, 'commerce', 'cart') });
      setMessage(t('product.added'));
    } catch (cause) {
      handleMutationError(cause, t('common.error'));
    } finally {
      setBusy(false);
    }
  }
  async function contactSeller() {
    if (!user) return requireLogin();
    setBusy(true);
    setMessage('');
    try {
      const conversation = await api.post<Conversation>('/chat/conversations', {
        targetUserId: product.sellerId,
        productId: product.id,
      });
      navigate(path(pathsFor.conversation(conversation.conversationId)), {
        state: productInquiryDraftState(product.id, product.sellerId),
      });
    } catch (cause) {
      handleMutationError(cause, t('product.contactError'));
    } finally {
      setBusy(false);
    }
  }
  async function toggleFollow() {
    if (!user) return requireLogin();
    setBusy(true);
    setMessage('');
    try {
      if (follow.data?.isFollowing) await api.patch(`/users/${product.sellerId}/unfollow`);
      else await api.post(`/users/${product.sellerId}/follow`);
      await cache.invalidateQueries({ queryKey: followKey });
      await cache.invalidateQueries({ queryKey: userKey(user.id, 'profile', product.sellerId) });
    } catch (cause) {
      handleMutationError(cause, t('common.error'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5">
      <div ref={redirectRef} className="sr-only" aria-hidden />
      <div className="grid grid-cols-1 items-start gap-8 lg:grid-cols-[minmax(0,1.5fr)_minmax(18rem,0.85fr)]">
        <ImageCarousel
          images={product.images.map((image) => ({
            id: image.id ?? image.url,
            url: mediaUrl(image.url),
          }))}
          alt={(index) => t('product.imageAlt', { title: product.title, index: index + 1 })}
          label={t('product.gallery')}
          noImage={t('product.noImage')}
          previousLabel={t('product.previousImage')}
          nextLabel={t('product.nextImage')}
          imageLabel={(index) =>
            t('product.imageOf', { index: index + 1, total: product.images.length })
          }
          openLabel={(index) => t('product.openImage', { index: index + 1 })}
          closeLabel={t('common.close')}
        />
        <Surface tone="base" className="grid items-start gap-0">
          <section className="grid gap-2 border-b border-edge/25 py-4 last:border-b-0">
            <PageHeader
              title={product.title}
              description={t(`condition.${product.condition}`)}
              actions={
                <Status tone={listingStatusTone(product.status)}>
                  {t(`status.${product.status}`)}
                </Status>
              }
            />
          </section>
          <section className="grid gap-2 border-b border-edge/25 py-4 last:border-b-0">
            <p className="m-0 font-display text-base font-bold">
              {formatMoney(product.price, locale)}
            </p>
            <p className="m-0 text-[13px] text-muted">{t('product.stock', { count: stock })}</p>
          </section>
          <section className="grid gap-2 border-b border-edge/25 py-4 last:border-b-0">
            <h2 className="m-0 font-display text-xs font-bold uppercase tracking-[.08em] text-muted">
              {t('product.description')}
            </h2>
            <p>{product.description}</p>
          </section>
          <section className="grid gap-2 border-b border-edge/25 py-4 last:border-b-0">
            <h2 className="m-0 font-display text-xs font-bold uppercase tracking-[.08em] text-muted">
              {t('product.seller')}
            </h2>
            <div className="flex items-center gap-4">
              <Avatar
                src={product.seller.avatarUrl ? mediaUrl(product.seller.avatarUrl) : null}
                name={product.seller.displayName}
              />
              <div>
                <Link to={path(pathsFor.person(product.seller.id))}>
                  {product.seller.displayName}
                  {product.seller.isVerified ? ' ✓' : ''}
                </Link>
                {product.seller.city && (
                  <p className="mt-0.5 text-[13px] text-muted">
                    {product.seller.city}
                    {product.seller.state ? `, ${product.seller.state}` : ''}
                  </p>
                )}
              </div>
            </div>
          </section>
          <section
            aria-label={t('product.reviews')}
            className="grid gap-2 border-b border-edge/25 py-4 last:border-b-0"
          >
            <h2 className="m-0 font-display text-xs font-bold uppercase tracking-[.08em] text-muted">
              {t('product.reviews')}
            </h2>
            {seller.isPending ? (
              <Loading label={t('common.loading')} rows={1} />
            ) : seller.isError ? (
              <ErrorState error={new Error(t('product.statsError'))} />
            ) : (
              <p className="m-0 font-display text-sm font-bold">
                {seller.data.reputationScore} / 5 ·{' '}
                {t('product.reviewCount', { count: seller.data.totalReviews })}
              </p>
            )}
            {reviews.isPending ? (
              <Loading label={t('common.loading')} rows={1} />
            ) : reviews.isError ? (
              <ErrorState error={new Error(t('common.error'))} />
            ) : (
              reviews.data.reviews.map((review) => (
                <p key={review.id}>
                  ★ {review.score} · {review.reviewer.displayName}
                  {review.comment ? ` — ${review.comment}` : ''}
                </p>
              ))
            )}
            <Link to={path(pathsFor.userReviews(product.sellerId))}>{t('reviewList.title')}</Link>
          </section>
          {canBuy && (
            <section className="grid gap-3.5 border-b border-edge/25 py-4 last:border-b-0">
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
                  className="grid size-11 place-items-center border border-edge bg-transparent text-ink transition-colors duration-150 hover:enabled:bg-surface-mid focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                  disabled={busy || isPending || !quantityValid}
                  onClick={() => void addToCart()}
                  aria-label={t('product.addCart')}
                  title={t('product.addCart')}
                >
                  <Icon name="cart" size={20} />
                </button>
                <button
                  type="button"
                  className={`grid size-11 place-items-center border border-edge bg-transparent text-ink transition-colors duration-150 hover:enabled:bg-surface-mid focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2 disabled:cursor-not-allowed disabled:opacity-50${saved ? ' bg-surface-mid text-brand' : ''}`}
                  aria-label={saved ? t('product.unfavorite') : t('product.favorite')}
                  aria-pressed={saved}
                  disabled={
                    busy || isPending || Boolean(user && (favorite.isPending || favorite.isError))
                  }
                  onClick={() => void toggleFavorite()}
                >
                  <Icon name="heart" size={20} />
                </button>
                <button
                  type="button"
                  className="grid size-11 place-items-center border border-edge bg-transparent text-ink transition-colors duration-150 hover:enabled:bg-surface-mid focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                  disabled={busy || isPending}
                  onClick={() => void contactSeller()}
                  aria-label={t('product.contact')}
                  title={t('product.contact')}
                >
                  <Icon name="comment" size={20} />
                </button>
                <button
                  type="button"
                  className={`grid size-11 place-items-center border border-edge bg-transparent text-ink transition-colors duration-150 hover:enabled:bg-surface-mid focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2 disabled:cursor-not-allowed disabled:opacity-50${follow.data?.isFollowing ? ' bg-surface-mid text-brand' : ''}`}
                  disabled={busy || isPending || follow.isPending || follow.isError}
                  aria-pressed={follow.data?.isFollowing === true}
                  onClick={() => void toggleFollow()}
                  aria-label={
                    follow.data?.isFollowing ? t('product.following') : t('product.follow')
                  }
                  title={follow.data?.isFollowing ? t('product.following') : t('product.follow')}
                >
                  <Icon name={follow.data?.isFollowing ? 'unfollow' : 'follow'} size={20} />
                </button>
              </div>
              <Link
                className={buttonClass('primary')}
                to={path(`${pathsFor.product(product.id)}/buy`)}
              >
                {t('buy.continue')}
              </Link>
              {favorite.isError && user && <ErrorState error={new Error(t('common.error'))} />}
              {favorite.isError && user && (
                <Button variant="ghost" onClick={() => void favorite.refetch()}>
                  {t('common.retry')}
                </Button>
              )}
              {follow.isError && user && (
                <>
                  <ErrorState error={new Error(t('common.error'))} />
                  <Button variant="ghost" onClick={() => void follow.refetch()}>
                    {t('common.retry')}
                  </Button>
                </>
              )}
            </section>
          )}
          {isOwner && <Link to={path(pathsFor.editProduct(product.id))}>{t('editor.edit')}</Link>}
          {message && (
            <p role="status" className="m-0">
              {message}
            </p>
          )}
        </Surface>
      </div>
    </section>
  );
}

export function ErrorBoundary() {
  const error = useRouteError();
  const { t } = useI18n(catalogs);
  const { path } = useLocale();
  return (
    <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5">
      <ErrorState
        error={
          new Error(
            (isRouteErrorResponse(error) && error.status === 404) ||
            (error instanceof ApiError && error.status === 404)
              ? t('product.notFound')
              : t('product.loadError'),
          )
        }
      />
      <Link to={path(paths.explore)}>{t('common.back')}</Link>
    </section>
  );
}
