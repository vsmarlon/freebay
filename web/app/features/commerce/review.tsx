import { useState, type FormEvent } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router';
import { Button, CommercePage, ErrorState, Input, Loading, RequireAuth, Surface, TextArea, useCommerce, useCommerceQuery } from './shared';
import { commerceApi } from './api';
import { userKey } from '../../core/query-client';
import { reviewTargetId, type ReviewEligibility } from './types';
import { paths } from '../../core/routes';

function ReviewContent() {
  const { id, user, t, path } = useCommerce();
  const client = useQueryClient();
  const [score, setScore] = useState(5);
  const [comment, setComment] = useState('');
  const [imageIds, setImageIds] = useState<string[]>([]);
  const [fileError, setFileError] = useState<string | null>(null);
  const orderQuery = useCommerceQuery('order-for-review', [id], (signal) => commerceApi.order(id, signal), Boolean(id));
  const eligibilityQuery = useCommerceQuery<ReviewEligibility>('review-eligibility', [id], (signal) => commerceApi.reviewEligibility(id, signal), Boolean(id));
  const upload = useMutation({ mutationFn: (files: File[]) => Promise.all(files.map((file) => commerceApi.uploadReviewImage(id, file))), onSuccess: (items) => setImageIds((current) => [...current, ...items.map((item) => item.imageId)]) });
  const submit = useMutation({ mutationFn: ({ orderId, ...body }: { orderId: string; reviewedId: string; type: NonNullable<import('./types').ReviewEligibility['reviewType']>; score: number; comment?: string; imageIds?: string[] }) => commerceApi.createReview(orderId, body), onSuccess: () => client.invalidateQueries({ queryKey: userKey(user?.id ?? '', 'commerce') }) });
  const order = orderQuery.data;
  const eligibility = eligibilityQuery.data;
  const targetId = order && eligibility ? reviewTargetId(order, eligibility.reviewType) : null;
  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!targetId || !eligibility?.reviewType) return;
    submit.mutate({ orderId: id, reviewedId: targetId, type: eligibility.reviewType, score, ...(comment.trim() ? { comment: comment.trim() } : {}), ...(imageIds.length ? { imageIds } : {}) });
  }
  function selectImages(files: FileList | null) {
    if (!files) return;
    if (files.length > 5 - imageIds.length) { setFileError(t('commerce.review.tooMany')); return; }
    const picked = Array.from(files);
    const allowed = picked.filter((file) => file.size <= 5 * 1024 * 1024 && file.type.startsWith('image/'));
    if (allowed.length !== picked.length) { setFileError(t('commerce.review.fileInvalid')); return; }
    setFileError(null);
    if (allowed.length) upload.mutate(allowed);
  }
  if (orderQuery.isPending || eligibilityQuery.isPending) return <CommercePage title={t('commerce.review.title')}><Loading label={t('commerce.loading')}/></CommercePage>;
  if (orderQuery.isError || eligibilityQuery.isError || !order || !eligibility) return <CommercePage title={t('commerce.review.title')}><ErrorState error={orderQuery.error ?? eligibilityQuery.error}/></CommercePage>;
  return <CommercePage title={t('commerce.review.title')}>
    {submit.isSuccess ? <Surface><p role="status">{t('commerce.review.done')}</p></Surface> : !eligibility.canReview || !targetId || !user ? <Surface><p>{eligibility.reason ?? t('commerce.review.unavailable')}</p></Surface> : <Surface>
      <p>{order.product?.title}</p>
      <form className="commerce-form" onSubmit={(event) => void onSubmit(event)}>
        <Input label={t('commerce.review.score')} type="number" min={1} max={5} required value={score} onChange={(event) => setScore(Number(event.currentTarget.value))}/>
        <TextArea label={t('commerce.review.comment')} maxLength={500} value={comment} onChange={(event) => setComment(event.currentTarget.value)}/>
        <Input label={t('commerce.review.photos')} type="file" accept="image/*" multiple disabled={upload.isPending || imageIds.length >= 5} onChange={(event) => { selectImages(event.currentTarget.files); event.currentTarget.value = ''; }}/>
        {imageIds.length > 0 && <p>{imageIds.length} {t('commerce.review.attached')}</p>}
        {(fileError || upload.error || submit.error) && <ErrorState error={fileError ? new Error(fileError) : upload.error ?? submit.error}/>}
        {submit.isError && <Link className="ui-button ui-secondary" to={path(paths.orders)}>{t('commerce.review.reconcile')}</Link>}
        <Button disabled={submit.isPending || submit.isError || upload.isPending || imageIds.length > 5} pending={submit.isPending}>{t('commerce.review.submit')}</Button>
      </form>
    </Surface>}
  </CommercePage>;
}
export default function ReviewPage() { return <RequireAuth><ReviewContent/></RequireAuth>; }
