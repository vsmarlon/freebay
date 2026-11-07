import { useCallback, useState } from 'react';
import { Link, useLoaderData, useNavigate, useRouteError, isRouteErrorResponse, type LoaderFunctionArgs, type MetaFunction } from 'react-router';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ApiError, api } from '../../core/api';
import { Avatar, Button, ErrorState, Icon, Loading, PageHeader, Status, Surface } from '../../components';
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
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';
import './marketplace.css';

const catalogs = { en, 'pt-BR': pt };
type LoaderData = { product: ProductSummary };
export async function loader({ params }: LoaderFunctionArgs): Promise<LoaderData> {
  if (!params.id) throw new Response('Not found', { status: 404 });
  return getProduct(params.id);
}
export const meta: MetaFunction<typeof loader> = ({ data }) => data?.product ? [
  { title: `${data.product.title} — Freebay` },
  { name: 'description', content: data.product.description.slice(0, 160) },
  { property: 'og:title', content: `${data.product.title} — Freebay` },
  { property: 'og:description', content: data.product.description.slice(0, 200) },
  ...(data.product.images[0] ? [{ property: 'og:image', content: data.product.images[0].url }] : []),
] : [{ title: 'Freebay' }];

type Favorite = { isFavorited: boolean };
type Conversation = { conversationId: string };
type FollowStatus = { isFollowing: boolean; followersCount: number; followingCount: number };
type SellerProfile = { reputationScore: number; totalReviews: number };
type ReviewList = { reviews: Array<{ id: string; score: number; comment: string | null; reviewer: { displayName: string } }>; total: number; offset: number; limit: number };
function listingStatusTone(status: ProductSummary['status']): 'success' | 'warning' | 'error' | 'info' | 'neutral' {
  if (status === 'ACTIVE') return 'success';
  if (status === 'PAUSED') return 'warning';
  if (status === 'SOLD') return 'info';
  return 'neutral';
}

export default function ProductDetailRoute() {
  const { product } = useLoaderData<LoaderData>();
  const { locale, path } = useLocale(); const { t } = useI18n(catalogs); const { user, isPending } = useSession(); const cache = useQueryClient(); const navigate = useNavigate();
  const [quantity, setQuantity] = useState('1'); const [busy, setBusy] = useState(false); const [message, setMessage] = useState('');
  const isOwner = user?.id === product.sellerId;
  const stock = Math.max(0, product.quantity - product.soldCount);
  const maxCartQuantity = Math.min(10, stock);
  const selectedQuantity = Number(quantity);
  const quantityValid = Number.isSafeInteger(selectedQuantity) && selectedQuantity >= 1 && selectedQuantity <= maxCartQuantity;
  const canBuy = product.status === 'ACTIVE' && stock > 0 && !isOwner;
  const favoriteKey = user ? userKey(user.id, 'favorites', product.id) : ['anonymous', 'favorite', product.id];
  const favorite = useQuery({ queryKey: favoriteKey, enabled: Boolean(user) && !isOwner, queryFn: () => api.get<Favorite>(`/favorites/check/${product.id}`) });
  const followKey = user ? userKey(user.id, 'follow', product.sellerId) : ['anonymous', 'follow', product.sellerId];
  const follow = useQuery({ queryKey: followKey, enabled: Boolean(user) && !isOwner, queryFn: () => api.get<FollowStatus>(`/users/${product.sellerId}/is-following`) });
  const seller = useQuery({ queryKey: ['public', 'seller', product.sellerId], queryFn: () => api.get<SellerProfile>(`/users/${product.sellerId}`, { auth: false }) });
  const reviews = useQuery({ queryKey: ['public', 'reviews', product.sellerId], queryFn: () => api.get<ReviewList>(`/reviews/users/${product.sellerId}?limit=5`, { auth: false }) });
  const saved = favorite.data?.isFavorited === true;
  const redirectRef = useCallback((node: HTMLDivElement | null) => { if (!node) return; const failure = favorite.error ?? follow.error; if (failure instanceof ApiError && failure.status === 401) navigate(path(paths.login)); }, [favorite.error, follow.error, navigate, path]);

  function requireLogin() { navigate(path(paths.login)); }
  function handleMutationError(cause: unknown, fallback: string) {
    if (cause instanceof ApiError && cause.status === 401) requireLogin();
    else setMessage(fallback);
  }
  async function toggleFavorite() {
    if (!user) return requireLogin();
    setBusy(true); setMessage('');
    try { await api.post(`/favorites/${product.id}`); await cache.invalidateQueries({ queryKey: favoriteKey }); await cache.invalidateQueries({ queryKey: userKey(user.id, 'favorites') }); }
    catch (cause) { handleMutationError(cause, t('common.error')); } finally { setBusy(false); }
  }
  async function addToCart() {
    if (!user) return requireLogin();
    setBusy(true); setMessage('');
    try { await api.post(`/cart/${product.id}`, { quantity: selectedQuantity }); await cache.invalidateQueries({ queryKey: userKey(user.id, 'commerce', 'cart') }); setMessage(t('product.added')); }
    catch (cause) { handleMutationError(cause, t('common.error')); } finally { setBusy(false); }
  }
  async function contactSeller() {
    if (!user) return requireLogin();
    setBusy(true); setMessage('');
    try { const conversation = await api.post<Conversation>('/chat/conversations', { targetUserId: product.sellerId, productId: product.id }); navigate(path(pathsFor.conversation(conversation.conversationId)), { state: productInquiryDraftState(product.id, product.sellerId) }); }
    catch (cause) { handleMutationError(cause, t('product.contactError')); } finally { setBusy(false); }
  }
  async function toggleFollow() {
    if (!user) return requireLogin();
    setBusy(true); setMessage('');
    try { if (follow.data?.isFollowing) await api.patch(`/users/${product.sellerId}/unfollow`); else await api.post(`/users/${product.sellerId}/follow`); await cache.invalidateQueries({ queryKey: followKey }); await cache.invalidateQueries({ queryKey: userKey(user.id, 'profile', product.sellerId) }); }
    catch (cause) { handleMutationError(cause, t('common.error')); } finally { setBusy(false); }
  }

  return (
    <section className="marketplace">
      <div ref={redirectRef} className="sr-only" aria-hidden />
      <div className="market-detail">
      <ImageCarousel images={product.images.map((image) => ({ id: image.id ?? image.url, url: mediaUrl(image.url) }))} alt={(index) => t('product.imageAlt', { title: product.title, index: index + 1 })} label={t('product.gallery')} noImage={t('product.noImage')} previousLabel={t('product.previousImage')} nextLabel={t('product.nextImage')} imageLabel={(index) => t('product.imageOf', { index: index + 1, total: product.images.length })} />
      <Surface tone="base" className="market-panel">
        <section className="market-block">
          <PageHeader title={product.title} description={t(`condition.${product.condition}`)} actions={<Status tone={listingStatusTone(product.status)}>{t(`status.${product.status}`)}</Status>} />
        </section>
        <section className="market-block">
          <p className="market-price">{formatMoney(product.price, locale)}</p>
          <p className="market-stock">{t('product.stock', { count: stock })}</p>
        </section>
        <section className="market-block">
          <h2 className="market-block-title">{t('product.description')}</h2>
          <p>{product.description}</p>
        </section>
        <section className="market-block">
          <h2 className="market-block-title">{t('product.seller')}</h2>
          <div className="market-owner">
            <Avatar src={product.seller.avatarUrl ? mediaUrl(product.seller.avatarUrl) : null} name={product.seller.displayName} />
            <div>
              <Link to={path(pathsFor.person(product.seller.id))}>{product.seller.displayName}{product.seller.isVerified ? ' ✓' : ''}</Link>
              {product.seller.city && <p className="market-location">{product.seller.city}{product.seller.state ? `, ${product.seller.state}` : ''}</p>}
            </div>
          </div>
        </section>
        <section aria-label={t('product.reviews')} className="market-block">
          <h2 className="market-block-title">{t('product.reviews')}</h2>
          {seller.isPending ? <Loading label={t('common.loading')} rows={1} /> : seller.isError ? <ErrorState error={new Error(t('product.statsError'))} /> : <p className="market-reviews-summary">{seller.data.reputationScore} / 5 · {t('product.reviewCount', { count: seller.data.totalReviews })}</p>}
          {reviews.isPending ? <Loading label={t('common.loading')} rows={1} /> : reviews.isError ? <ErrorState error={new Error(t('common.error'))} /> : reviews.data.reviews.map((review) => <p key={review.id}>★ {review.score} · {review.reviewer.displayName}{review.comment ? ` — ${review.comment}` : ''}</p>)}
          <Link to={path(pathsFor.userReviews(product.sellerId))}>{t('reviewList.title')}</Link>
        </section>
        {canBuy && (
          <section className="market-block market-buy">
            <div className="market-quantity-row">
              <QuantityStepper label={t('product.quantity')} increase={t('product.increase')} decrease={t('product.decrease')} value={Math.max(1, Math.min(maxCartQuantity, Number(quantity) || 1))} max={maxCartQuantity} disabled={busy || isPending} onCommit={(next) => setQuantity(String(next))} />
            </div>
            <div className="market-icon-actions">
              <button type="button" className="market-icon-button" disabled={busy || isPending || !quantityValid} onClick={() => void addToCart()} aria-label={t('product.addCart')} title={t('product.addCart')}>
                <Icon name="cart" size={20} />
              </button>
              <button type="button" className={`market-icon-button${saved ? ' market-icon-button-active' : ''}`} aria-label={saved ? t('product.unfavorite') : t('product.favorite')} aria-pressed={saved} disabled={busy || isPending || Boolean(user && (favorite.isPending || favorite.isError))} onClick={() => void toggleFavorite()}>
                <Icon name="heart" size={20} />
              </button>
              <button type="button" className="market-icon-button" disabled={busy || isPending} onClick={() => void contactSeller()} aria-label={t('product.contact')} title={t('product.contact')}>
                <Icon name="comment" size={20} />
              </button>
              <button type="button" className={`market-icon-button${follow.data?.isFollowing ? ' market-icon-button-active' : ''}`} disabled={busy || isPending || follow.isPending || follow.isError} aria-pressed={follow.data?.isFollowing === true} onClick={() => void toggleFollow()} aria-label={follow.data?.isFollowing ? t('product.following') : t('product.follow')} title={follow.data?.isFollowing ? t('product.following') : t('product.follow')}>
                <Icon name={follow.data?.isFollowing ? 'unfollow' : 'follow'} size={20} />
              </button>
            </div>
            <Link className="ui-button ui-primary" to={path(`${pathsFor.product(product.id)}/buy`)}>{t('buy.continue')}</Link>
            {favorite.isError && user && <ErrorState error={new Error(t('common.error'))} />}
            {favorite.isError && user && <Button variant="ghost" onClick={() => void favorite.refetch()}>{t('common.retry')}</Button>}
            {follow.isError && user && <><ErrorState error={new Error(t('common.error'))} /><Button variant="ghost" onClick={() => void follow.refetch()}>{t('common.retry')}</Button></>}
          </section>
        )}
        {isOwner && <Link to={path(pathsFor.editProduct(product.id))}>{t('editor.edit')}</Link>}
        {message && <p role="status" className="market-message">{message}</p>}
      </Surface>
    </div>
  </section>
);
}

export function ErrorBoundary() {
  const error = useRouteError(); const { t } = useI18n(catalogs); const { path } = useLocale();
  return <section className="marketplace"><ErrorState error={new Error((isRouteErrorResponse(error) && error.status === 404) || (error instanceof ApiError && error.status === 404) ? t('product.notFound') : t('product.loadError'))} /><Link to={path(paths.explore)}>{t('common.back')}</Link></section>;
}
