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
  return <article><Surface className="market-card">
    <Link className="market-card-media" to={path(pathsFor.product(product.id))} aria-label={t('product.open', { title: product.title })}>
      {image ? <img src={mediaUrl(image.url)} alt={product.title} loading="lazy" /> : <span className="market-no-image">{t('product.noImage')}</span>}
      {product.status !== 'ACTIVE' && <span className="market-tag"><Status tone={product.status === 'SOLD' || product.status === 'DELETED' ? 'error' : 'warning'}>{t(`status.${product.status}`)}</Status></span>}
    </Link>
    <div className="market-card-copy">
      <h2><Link to={path(pathsFor.product(product.id))}>{product.title}</Link></h2>
      <p className="market-price">{formatMoney(product.price, locale)}</p>
      <div className="market-card-meta"><span>{t(`condition.${product.condition}`)}</span><Link className="market-card-seller" to={path(pathsFor.person(product.seller.id))}><Avatar src={product.seller.avatarUrl ? mediaUrl(product.seller.avatarUrl) : null} name={product.seller.displayName} size={20} /><span className="market-card-store">{product.seller.displayName}</span></Link></div>
    </div>
  </Surface></article>;
}

export function ProductGrid({ products }: { products: ProductSummary[] }) {
  return <div className="market-grid">{products.map((product) => <ProductCard key={product.id} product={product} />)}</div>;
}
