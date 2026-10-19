import { useEffect, useState } from 'react';
import { Link, useLoaderData, useNavigate, useRouteError, isRouteErrorResponse, type LoaderFunctionArgs, type MetaFunction } from 'react-router';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ApiError, api } from '../../core/api';
import { Avatar, Button, ErrorState, IconButton, Input, Loading, PageHeader, Status, Surface } from '../../components';
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
  useEffect(() => { const failure = favorite.error ?? follow.error; if (failure instanceof ApiError && failure.status === 401) navigate(path(paths.login)); }, [favorite.error, follow.error, navigate, path]);

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
    try { await api.post(`/cart/${product.id}`, { quantity: selectedQuantity }); await cache.invalidateQueries({ queryKey: userKey(user.id, 'cart') }); setMessage(t('product.added')); }
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

  return <section className="marketplace"><div className="market-detail">
    <section aria-label={t('product.gallery')} className="market-gallery">{product.images.length ? product.images.map((image, index) => <img key={image.id ?? image.url} src={mediaUrl(image.url)} alt={t('product.imageAlt', { title: product.title, index: index + 1 })} fetchPriority={index === 0 ? 'high' : 'auto'} />) : <Surface tone="mid">{t('product.noImage')}</Surface>}</section>
    <Surface tone="base" className="market-panel">
      <PageHeader title={product.title} description={t(`condition.${product.condition}`)} actions={<Status tone={listingStatusTone(product.status)}>{t(`status.${product.status}`)}</Status>} />
      <p className="market-price">{formatMoney(product.price, locale)}</p><p>{t('product.stock', { count: stock })}</p>
      <h2>{t('product.description')}</h2><p>{product.description}</p>
      <div className="market-owner"><Avatar src={product.seller.avatarUrl ? mediaUrl(product.seller.avatarUrl) : null} name={product.seller.displayName} /><div><strong>{t('product.seller')}</strong><br /><Link to={path(pathsFor.person(product.seller.id))}>{product.seller.displayName}{product.seller.isVerified ? ' ✓' : ''}</Link>{product.seller.city && <p>{product.seller.city}{product.seller.state ? `, ${product.seller.state}` : ''}</p>}</div></div>
       <section aria-label={t('product.reviews')}><h2>{t('product.reviews')}</h2>{seller.isPending ? <Loading label={t('common.loading')} rows={1} /> : seller.isError ? <ErrorState error={new Error(t('product.statsError'))} /> : <p>{seller.data.reputationScore} / 5 · {t('product.reviewCount', { count: seller.data.totalReviews })}</p>}{reviews.isPending ? <Loading label={t('common.loading')} rows={1} /> : reviews.isError ? <ErrorState error={new Error(t('common.error'))} /> : reviews.data.reviews.map((review) => <p key={review.id}>★ {review.score} · {review.reviewer.displayName}{review.comment ? ` — ${review.comment}` : ''}</p>)}<Link to={path(pathsFor.userReviews(product.sellerId))}>{t('reviewList.title')}</Link></section>
       {canBuy && <div className="market-actions"><Input label={t('product.quantity')} type="number" min={1} max={maxCartQuantity} step={1} value={quantity} onChange={(event) => setQuantity(event.currentTarget.value)} /><Button disabled={busy || isPending || !quantityValid} pending={busy} onClick={() => void addToCart()}>{t('product.addCart')}</Button><Link className="ui-button ui-primary" to={path(`${pathsFor.product(product.id)}/buy`)}>{t('buy.continue')}</Link></div>}
      {!isOwner && <div className="market-actions">
        {favorite.isError && user && <ErrorState error={new Error(t('common.error'))} />}
        <IconButton className={`market-favorite${saved ? ' market-favorite-saved' : ''}`} aria-label={saved ? t('product.unfavorite') : t('product.favorite')} type="button" disabled={busy || isPending || Boolean(user && (favorite.isPending || favorite.isError))} aria-pressed={saved} onClick={() => void toggleFavorite()} />
        {favorite.isError && user && <Button variant="ghost" onClick={() => void favorite.refetch()}>{t('common.retry')}</Button>}
        <Button variant="secondary" disabled={busy || isPending} onClick={() => void contactSeller()}>{t('product.contact')}</Button>
        {follow.isError && user && <><ErrorState error={new Error(t('common.error'))} /><Button variant="ghost" onClick={() => void follow.refetch()}>{t('common.retry')}</Button></>}
        {user && <Button variant="secondary" disabled={busy || isPending || follow.isPending || follow.isError} aria-pressed={follow.data?.isFollowing === true} onClick={() => void toggleFollow()}>{follow.data?.isFollowing ? t('product.following') : t('product.follow')}</Button>}
      </div>}
      {isOwner && <Link to={path(pathsFor.editProduct(product.id))}>{t('editor.edit')}</Link>}
      {message && <p role="status">{message}</p>}
    </Surface>
  </div></section>;
}

export function ErrorBoundary() {
  const error = useRouteError(); const { t } = useI18n(catalogs); const { path } = useLocale();
  return <section className="marketplace"><ErrorState error={new Error((isRouteErrorResponse(error) && error.status === 404) || (error instanceof ApiError && error.status === 404) ? t('product.notFound') : t('product.loadError'))} /><Link to={path(paths.explore)}>{t('common.back')}</Link></section>;
}
