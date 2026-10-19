import { Link } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { Button, Empty, ErrorState, Loading, PageHeader, Surface } from '../../components';
import { api } from '../../core/api';
import { useLocale, useI18n } from '../../core/locale';
import { useSession } from '../../core/session';
import { paths, pathsFor } from '../../core/routes';
import { mediaUrl } from '../../core/media';
import { userKey } from '../../core/query-client';
import type { ProductSummary } from './types';
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';
import './marketplace.css';

const catalogs = { en, 'pt-BR': pt };

export default function MyProductsRoute() {
  const { user, isPending } = useSession();
  const { path } = useLocale();
  const { t } = useI18n(catalogs);
  const query = useQuery({
    queryKey: userKey(user?.id ?? 'anonymous', 'products', 'mine'),
    enabled: Boolean(user),
    queryFn: () => api.get<{ products: ProductSummary[] }>('/products/mine/all'),
  });
  if (isPending) return <section className="marketplace"><Loading label={t('common.loading')} /></section>;
  if (!user) return <section className="marketplace"><Surface><p>{t('auth.required')}</p><Button onClick={() => window.location.assign(path(paths.login))}>{t('auth.signIn')}</Button></Surface></section>;
  return <section className="marketplace">
    <PageHeader title={t('myProducts.title')} actions={<Link className="ui-button ui-primary" to={path(paths.sell)}>{t('catalog.sell')}</Link>} />
    {query.isPending ? <Loading label={t('common.loading')} /> : query.isError ? <ErrorState error={query.error} onRetry={() => void query.refetch()} /> : query.data.products.length ? <div className="market-grid">{query.data.products.map((product) => <Surface key={product.id}>
      {product.images[0] && <img src={mediaUrl(product.images[0].url)} alt={product.title} loading="lazy" />}
      <h2>{product.title}</h2><p>{t(`status.${product.status}`)} · {t('editor.quantity')}: {Math.max(0, product.quantity - product.soldCount)}</p>
      <Link className="ui-button ui-secondary" to={path(pathsFor.editProduct(product.id))}>{t('editor.edit')}</Link>
    </Surface>)}</div> : <Empty title={t('myProducts.empty')} />}
  </section>;
}
