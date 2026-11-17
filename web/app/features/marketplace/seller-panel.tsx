import { Link } from 'react-router';
import { Avatar, ErrorState, Loading } from '../../components';
import { useLocale, useI18n } from '../../core/locale';
import { mediaUrl } from '../../core/media';
import { pathsFor } from '../../core/routes';
import { useSellerProfile, useSellerReviews } from './queries';
import type { ProductSeller } from './types';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };

// Seller identity plus the reputation/review lookups it displays; the detail route
// only decides where the block sits.
export function SellerPanel({ seller }: { seller: ProductSeller }) {
  const { path } = useLocale();
  const { t } = useI18n(catalogs);
  const profile = useSellerProfile(seller.id);
  const reviews = useSellerReviews(seller.id);
  return (
    <>
      <section className="grid gap-2 border-b border-edge/25 py-4 last:border-b-0">
        <h2 className="m-0 font-display text-xs font-bold uppercase tracking-[.08em] text-muted">
          {t('product.seller')}
        </h2>
        <div className="flex items-center gap-4">
          <Avatar
            src={seller.avatarUrl ? mediaUrl(seller.avatarUrl) : null}
            name={seller.displayName}
          />
          <div>
            <Link to={path(pathsFor.person(seller.id))}>
              {seller.displayName}
              {seller.isVerified ? ' ✓' : ''}
            </Link>
            {seller.city && (
              <p className="mt-0.5 text-[13px] text-muted">
                {seller.city}
                {seller.state ? `, ${seller.state}` : ''}
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
        {profile.isPending ? (
          <Loading label={t('common.loading')} rows={1} />
        ) : profile.isError ? (
          <ErrorState error={new Error(t('product.statsError'))} />
        ) : (
          <p className="m-0 font-display text-sm font-bold">
            {profile.data.reputationScore} / 5 ·{' '}
            {t('product.reviewCount', { count: profile.data.totalReviews })}
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
        <Link to={path(pathsFor.userReviews(seller.id))}>{t('reviewList.title')}</Link>
      </section>
    </>
  );
}
