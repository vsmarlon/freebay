import { useState } from 'react';
import { Link, useParams } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { Button, Empty, ErrorState, Loading, PageHeader, Select, Surface } from '../../components';
import { api } from '../../core/api';
import { mediaUrl } from '../../core/media';
import { useLocale, useI18n } from '../../core/locale';
import { pathsFor } from '../../core/routes';
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';
import '../commerce/commerce.css';

const catalogs = { en, 'pt-BR': pt };
type ReviewType = '' | 'BUYER_REVIEWING_SELLER' | 'SELLER_REVIEWING_BUYER';
type ReviewPage = { reviews: Array<{ id: string; score: number; comment: string | null; type: Exclude<ReviewType, ''>; createdAt: string; images: Array<{ id: string; url: string; order: number }>; reviewer: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean } }>; total: number; offset: number; limit: number };

export default function UserReviewsRoute() {
  const { id = '' } = useParams();
  const { path } = useLocale(); const { t } = useI18n(catalogs);
  const [type, setType] = useState<ReviewType>(''); const [offset, setOffset] = useState(0);
  const query = useQuery({ queryKey: ['public', 'reviews', id, type, offset], enabled: Boolean(id), queryFn: () => {
    const params = new URLSearchParams({ offset: String(offset), limit: '20' }); if (type) params.set('type', type);
    return api.get<ReviewPage>(`/reviews/users/${encodeURIComponent(id)}?${params}`, { auth: false });
  } });
  return <section className="marketplace">
    <PageHeader title={t('reviewList.title')} />
    <Select label={t('reviewList.filter')} value={type} onChange={(event) => { setType(event.currentTarget.value as ReviewType); setOffset(0); }}>
      <option value="">{t('reviewList.all')}</option><option value="BUYER_REVIEWING_SELLER">{t('reviewList.seller')}</option><option value="SELLER_REVIEWING_BUYER">{t('reviewList.buyer')}</option>
    </Select>
    {query.isPending ? <Loading label={t('common.loading')} /> : query.isError ? <ErrorState error={query.error} onRetry={() => void query.refetch()} /> : query.data.reviews.length ? <div className="commerce-list">{query.data.reviews.map((review) => <Surface key={review.id}>
      <p>{review.reviewer.displayName}{review.reviewer.isVerified ? ' ✓' : ''} · {review.score}/5 · {new Date(review.createdAt).toLocaleDateString()}</p>
      {review.comment && <p>{review.comment}</p>}
      {review.images.map((image) => <img key={image.id} src={mediaUrl(image.url)} alt="" loading="lazy" />)}
      <small>{review.type === 'BUYER_REVIEWING_SELLER' ? t('reviewList.seller') : t('reviewList.buyer')}</small>
    </Surface>)}</div> : <Empty title={t('reviewList.empty')} />}
    {query.data && <div className="commerce-actions"><Button variant="secondary" disabled={offset === 0} onClick={() => setOffset(Math.max(0, offset - query.data!.limit))}>{t('reviewList.previous')}</Button><Button variant="secondary" disabled={offset + query.data.reviews.length >= query.data.total} onClick={() => setOffset(offset + query.data!.limit)}>{t('reviewList.next')}</Button></div>}
    <Link className="ui-button ui-secondary" to={path(pathsFor.person(id))}>{t('reviewList.profile')}</Link>
  </section>;
}
