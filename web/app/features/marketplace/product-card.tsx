import { Link } from 'react-router';
import { formatMoney } from '../../core/money';
import { pathsFor } from '../../core/routes';
import { useI18n, useLocale } from '../../core/locale';
import { mediaUrl } from '../../core/media';
import { Avatar, Status, Surface } from '../../components';
import type { ProductSummary } from './types';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };

export function ProductCard({ product }: { product: ProductSummary }) {
  const { locale, path } = useLocale();
  const { t } = useI18n(catalogs);
  const image = product.images[0];
  return (
    <article>
      <Surface className="flex h-full min-w-0 flex-col">
        <Link
          className="relative block aspect-square overflow-hidden bg-surface-mid sm:aspect-4/3"
          to={path(pathsFor.product(product.id))}
          aria-label={t('product.open', { title: product.title })}
        >
          {image ? (
            <img
              className="block size-full object-cover"
              src={mediaUrl(image.url)}
              alt={product.title}
              loading="lazy"
            />
          ) : (
            <span className="grid size-full place-items-center p-2 text-center text-[11px] font-bold text-muted">
              {t('product.noImage')}
            </span>
          )}
          {product.status !== 'ACTIVE' && (
            <span className="absolute left-2 top-2">
              <Status
                tone={
                  product.status === 'SOLD' || product.status === 'DELETED' ? 'error' : 'warning'
                }
              >
                {t(`status.${product.status}`)}
              </Status>
            </span>
          )}
        </Link>
        <div className="flex flex-1 flex-col gap-2">
          <h2 className="line-clamp-2 min-h-[2.6em] wrap-break-word text-[15px] leading-[1.3]">
            <Link to={path(pathsFor.product(product.id))}>{product.title}</Link>
          </h2>
          <p className="m-0 font-display text-base font-bold">
            {formatMoney(product.price, locale)}
          </p>
          <div className="mt-auto flex items-center gap-2">
            <span className="shrink-0 bg-surface-high px-1.5 py-0.5 text-[11px] font-bold">
              {t(`condition.${product.condition}`)}
            </span>
            <Link
              className="ml-auto inline-flex min-w-0 items-center gap-1.5 text-xs font-semibold text-ink no-underline"
              to={path(pathsFor.person(product.seller.id))}
            >
              <Avatar
                src={product.seller.avatarUrl ? mediaUrl(product.seller.avatarUrl) : null}
                name={product.seller.displayName}
                size={20}
              />
              <span className="truncate  ">{product.seller.displayName}</span>
            </Link>
          </div>
        </div>
      </Surface>
    </article>
  );
}

export function ProductGrid({ products }: { products: ProductSummary[] }) {
  return (
    <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
      {products.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
