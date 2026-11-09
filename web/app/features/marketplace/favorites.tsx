import { useCallback, useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ApiError, api } from '../../core/api';
import { Avatar, Button, Empty, ErrorState, Loading, PageHeader, Surface } from '../../components';
import { useSession } from '../../core/session';
import { useLocale, useI18n } from '../../core/locale';
import { paths, pathsFor } from '../../core/routes';
import { userKey } from '../../core/query-client';
import { formatMoney } from '../../core/money';
import { mediaUrl } from '../../core/media';
import type { ProductSummary } from './types';
import { toProductSummary } from './types';
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };
type FavoriteRecord = { id: string; product: ProductSummary };
type FavoriteResponse = FavoriteRecord[] | { products: Array<ProductSummary | FavoriteRecord> };
function entriesFrom(value: FavoriteResponse): ProductSummary[] {
  const rows = Array.isArray(value) ? value : value.products;
  return rows.map((row) => toProductSummary('product' in row ? row.product : row));
}
export default function FavoritesRoute() {
  const { user, isPending } = useSession(); const { locale, path } = useLocale(); const { t } = useI18n(catalogs); const client = useQueryClient(); const navigate = useNavigate();
  const userId = user?.id;
  const query = useQuery({ queryKey: userId ? userKey(userId, 'favorites', 'list') : ['user', 'signed-out', 'favorites'], enabled: Boolean(userId), queryFn: async () => entriesFrom(await api.get<FavoriteResponse>('/favorites')) });
  const [busyId, setBusyId] = useState<string | null>(null); const [actionError, setActionError] = useState('');
  const redirectRef = useCallback((node: HTMLDivElement | null) => { if (node && query.error instanceof ApiError && query.error.status === 401) navigate(path(paths.login)); }, [navigate, path, query.error]);
  if (isPending) return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><Loading label={t('common.loading')} /></section>;
  if (!user) return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><Surface><PageHeader title={t('favorites.title')} description={t('auth.required')} /><Button onClick={() => navigate(path(paths.login))}>{t('auth.signIn')}</Button></Surface></section>;
  const signedInUserId = user.id;
  async function remove(id: string) {
    setBusyId(id); setActionError('');
    try { await api.post(`/favorites/${id}`); await client.invalidateQueries({ queryKey: userKey(signedInUserId, 'favorites') }); }
    catch (cause) { if (cause instanceof ApiError && cause.status === 401) navigate(path(paths.login)); else setActionError(t('common.error')); }
    finally { setBusyId(null); }
  }
  return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><div ref={redirectRef} className="sr-only" aria-hidden /><PageHeader title={t('favorites.title')} />
    {query.isPending ? <Loading label={t('common.loading')} /> : query.isError ? <><ErrorState error={new Error(t('common.error'))} /><Button variant="secondary" onClick={() => void query.refetch()}>{t('common.retry')}</Button></> : !query.data.length ? <Empty title={t('favorites.empty')} /> : <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">{query.data.map((product) => <article key={product.id}><Surface className="flex h-full min-w-0 flex-col"><Link className="relative block aspect-square overflow-hidden bg-surface-mid sm:aspect-4/3" to={path(pathsFor.product(product.id))}>{product.images[0] ? <img className="block size-full object-cover" src={mediaUrl(product.images[0].url)} alt={product.title} loading="lazy" /> : <span className="grid size-full place-items-center p-2 text-center text-[11px] font-bold text-muted">{t('product.noImage')}</span>}</Link><div className="flex flex-1 flex-col gap-2"><h2 className="line-clamp-2 min-h-[2.6em] wrap-break-word text-[15px] leading-[1.3]"><Link to={path(pathsFor.product(product.id))}>{product.title}</Link></h2><p className="m-0 font-display text-base font-bold">{formatMoney(product.price, locale)}</p><Link className="inline-flex min-w-0 items-center gap-1.5 text-xs font-semibold text-ink no-underline" to={path(pathsFor.person(product.seller.id))}><Avatar src={product.seller.avatarUrl ? mediaUrl(product.seller.avatarUrl) : null} name={product.seller.displayName} size={20} /><span className="truncate  ">{product.seller.displayName}</span></Link><Button variant="secondary" disabled={busyId === product.id} pending={busyId === product.id} onClick={() => void remove(product.id)}>{t('favorites.remove')}</Button></div></Surface></article>)}</div>}
    {actionError && <ErrorState error={new Error(actionError)} />}
  </section>;
}
