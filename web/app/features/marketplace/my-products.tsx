import { Link } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { Button, Empty, ErrorState, Loading, PageHeader, Surface, buttonClass } from '../../components';
import { api } from '../../core/api';
import { useLocale, useI18n } from '../../core/locale';
import { useSession } from '../../core/session';
import { paths, pathsFor } from '../../core/routes';
import { mediaUrl } from '../../core/media';
import { userKey } from '../../core/query-client';
import type { ProductSummary } from './types';
import { toProductSummary } from './types';
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };

export default function MyProductsRoute() {
  const { user, isPending } = useSession();
  const { path } = useLocale();
  const { t } = useI18n(catalogs);
  const query = useQuery({
    queryKey: userKey(user?.id ?? 'anonymous', 'products', 'mine'),
    enabled: Boolean(user),
    queryFn: async () => {
      const data = await api.get<{ products: ProductSummary[] }>('/products/mine/all');
      return { products: data.products.map(toProductSummary) };
    },
  });
  if (isPending) return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><Loading label={t('common.loading')} /></section>;
  if (!user) return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><Surface><p>{t('auth.required')}</p><Button onClick={() => window.location.assign(path(paths.login))}>{t('auth.signIn')}</Button></Surface></section>;
  return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5">
    <PageHeader title={t('myProducts.title')} actions={<Link className={buttonClass('primary')} to={path(paths.sell)}>{t('catalog.sell')}</Link>} />
    {query.isPending ? <Loading label={t('common.loading')} /> : query.isError ? <ErrorState error={query.error} onRetry={() => void query.refetch()} /> : query.data.products.length ? <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">{query.data.products.map((product) => <Surface key={product.id}>
      {product.images[0] && <img src={mediaUrl(product.images[0].url)} alt={product.title} loading="lazy" />}
      <h2>{product.title}</h2><p>{t(`status.${product.status}`)} · {t('editor.quantity')}: {Math.max(0, product.quantity - product.soldCount)}</p>
      <Link className={buttonClass('secondary')} to={path(pathsFor.editProduct(product.id))}>{t('editor.edit')}</Link>
    </Surface>)}</div> : <Empty title={t('myProducts.empty')} />}
  </section>;
}
