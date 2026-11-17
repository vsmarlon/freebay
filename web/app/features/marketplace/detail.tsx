import {
  Link,
  useLoaderData,
  useRouteError,
  isRouteErrorResponse,
  type LoaderFunctionArgs,
  type MetaFunction,
} from 'react-router';
import { PageSection } from '../../components/page-section';
import { RouteErrorBoundary } from '../../components/route-error-boundary';
import { ApiError } from '../../core/api';
import { PageHeader, Status, Surface } from '../../components';
import { useSession } from '../../core/session';
import { useLocale, useI18n } from '../../core/locale';
import { paths, pathsFor } from '../../core/routes';
import { formatMoney } from '../../core/money';
import type { ProductSummary } from './types';
import { getProduct } from './server.server';
import { ProductActions } from './product-actions';
import { ProductGallery } from './product-gallery';
import { SellerPanel } from './seller-panel';
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
  const { user } = useSession();
  const isOwner = user?.id === product.sellerId;
  const stock = Math.max(0, product.quantity - product.soldCount);
  // Availability is a display decision; the backend re-checks ownership, status and stock.
  const canBuy = product.status === 'ACTIVE' && stock > 0 && !isOwner;

  return (
    <PageSection>
      <div className="grid grid-cols-1 items-start gap-8 lg:grid-cols-[minmax(0,1.5fr)_minmax(18rem,0.85fr)]">
        <ProductGallery product={product} />
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
          <SellerPanel seller={product.seller} />
          {canBuy && <ProductActions product={product} stock={stock} />}
          {isOwner && <Link to={path(pathsFor.editProduct(product.id))}>{t('editor.edit')}</Link>}
        </Surface>
      </div>
    </PageSection>
  );
}

export function ErrorBoundary() {
  const error = useRouteError();
  const { t } = useI18n(catalogs);
  const { path } = useLocale();
  const notFound =
    (isRouteErrorResponse(error) && error.status === 404) ||
    (error instanceof ApiError && error.status === 404);
  return (
    <RouteErrorBoundary
      catalogs={catalogs}
      fallbackKey={notFound ? 'product.notFound' : 'product.loadError'}
      showRetry={false}
      action={<Link to={path(paths.explore)}>{t('common.back')}</Link>}
    />
  );
}
