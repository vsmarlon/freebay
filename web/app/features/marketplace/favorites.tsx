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
import './marketplace.css';

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
  if (isPending) return <section className="marketplace"><Loading label={t('common.loading')} /></section>;
  if (!user) return <section className="marketplace"><Surface><PageHeader title={t('favorites.title')} description={t('auth.required')} /><Button onClick={() => navigate(path(paths.login))}>{t('auth.signIn')}</Button></Surface></section>;
  const signedInUserId = user.id;
  async function remove(id: string) {
    setBusyId(id); setActionError('');
    try { await api.post(`/favorites/${id}`); await client.invalidateQueries({ queryKey: userKey(signedInUserId, 'favorites') }); }
    catch (cause) { if (cause instanceof ApiError && cause.status === 401) navigate(path(paths.login)); else setActionError(t('common.error')); }
    finally { setBusyId(null); }
  }
  return <section className="marketplace"><div ref={redirectRef} className="sr-only" aria-hidden /><PageHeader title={t('favorites.title')} />
    {query.isPending ? <Loading label={t('common.loading')} /> : query.isError ? <><ErrorState error={new Error(t('common.error'))} /><Button variant="secondary" onClick={() => void query.refetch()}>{t('common.retry')}</Button></> : !query.data.length ? <Empty title={t('favorites.empty')} /> : <div className="market-grid">{query.data.map((product) => <article key={product.id}><Surface className="market-card"><Link className="market-card-media" to={path(pathsFor.product(product.id))}>{product.images[0] ? <img src={mediaUrl(product.images[0].url)} alt={product.title} loading="lazy" /> : <span>{t('product.noImage')}</span>}</Link><div className="market-card-copy"><h2><Link to={path(pathsFor.product(product.id))}>{product.title}</Link></h2><p className="market-price">{formatMoney(product.price, locale)}</p><Link to={path(pathsFor.person(product.seller.id))}><Avatar src={product.seller.avatarUrl ? mediaUrl(product.seller.avatarUrl) : null} name={product.seller.displayName} />{product.seller.displayName}</Link><Button className="market-remove-favorite" variant="secondary" disabled={busyId === product.id} pending={busyId === product.id} onClick={() => void remove(product.id)}>{t('favorites.remove')}</Button></div></Surface></article>)}</div>}
    {actionError && <ErrorState error={new Error(actionError)} />}
  </section>;
}
