import { useEffect, useState, type FormEvent } from 'react';
import { useLoaderData, useNavigate, useRouteError, isRouteErrorResponse, type LoaderFunctionArgs } from 'react-router';
import { useQueryClient } from '@tanstack/react-query';
import { ApiError, api } from '../../core/api';
import { Button, Dialog, ErrorState, Input, Loading, PageHeader, Select, Surface, TextArea } from '../../components';
import { useSession } from '../../core/session';
import { useLocale, useI18n } from '../../core/locale';
import { paths, pathsFor } from '../../core/routes';
import { userKey } from '../../core/query-client';
import type { Category, ProductSummary } from './types';
import { getCategories, getProduct } from './server.server';
import { formatListingPriceInput, parseListingPrice, validateProductImage } from './listing-input';
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';
import './marketplace.css';

const catalogs = { en, 'pt-BR': pt };
type LoaderData = { product: ProductSummary | null; categories: Category[] };
export async function loader({ params }: LoaderFunctionArgs): Promise<LoaderData> {
  const categoryResult = await getCategories();
  return { categories: categoryResult.categories, product: params.id ? (await getProduct(params.id)).product : null };
}
type FormValues = { title: string; description: string; price: string; condition: 'NEW' | 'USED'; categoryId: string; quantity: string; status: 'ACTIVE' | 'PAUSED' };
function initial(product: ProductSummary | null, locale: 'pt-BR' | 'en'): FormValues { return { title: product?.title ?? '', description: product?.description ?? '', price: product ? formatListingPriceInput(product.price, locale) : '', condition: product?.condition ?? 'USED', categoryId: product?.categoryId ?? '', quantity: String(product?.quantity ?? 1), status: product?.status === 'PAUSED' ? 'PAUSED' : 'ACTIVE' }; }
function flatten(categories: Category[]): Category[] { return categories.flatMap((category) => [category, ...flatten(category.children ?? [])]); }
function isCondition(value: string): value is FormValues['condition'] { return value === 'NEW' || value === 'USED'; }
function isEditableStatus(value: string): value is FormValues['status'] { return value === 'ACTIVE' || value === 'PAUSED'; }

export default function ListingEditorRoute() {
  const { product, categories } = useLoaderData<LoaderData>(); const { user, isPending } = useSession(); const { locale, path } = useLocale(); const { t } = useI18n(catalogs); const navigate = useNavigate(); const client = useQueryClient();
  const [values, setValues] = useState(() => initial(product, locale)); const [file, setFile] = useState<File | null>(null); const [error, setError] = useState(''); const [busy, setBusy] = useState(false); const [confirmDelete, setConfirmDelete] = useState(false);
  useEffect(() => { setValues(initial(product, locale)); }, [locale, product]);
  const isEdit = product !== null;
  if (isPending) return <section className="marketplace"><Loading label={t('common.loading')} /></section>;
  if (!user) return <section className="marketplace"><Surface><p>{t('auth.required')}</p><Button onClick={() => navigate(path(paths.login))}>{t('auth.signIn')}</Button></Surface></section>;
  if (product && product.sellerId !== user.id) return <section className="marketplace"><ErrorState error={new Error(t('common.error'))} /></section>;
  if (product?.status === 'SOLD') return <section className="marketplace"><ErrorState error={new Error(t('editor.soldReadOnly'))} /></section>;
  const userId = user.id;
  function change<K extends keyof FormValues>(key: K, value: FormValues[K]) { setValues((current) => ({ ...current, [key]: value })); }
  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError('');
    if (!isEdit) { const imageError = validateProductImage(file); if (imageError) { setError(imageError === 'required' ? t('editor.requiredImage') : t('editor.imageInvalid')); return; } }
    let price: number; try { price = parseListingPrice(values.price, locale); } catch { setError(t('editor.invalidPrice')); return; }
    const quantity = Number(values.quantity); if (!Number.isSafeInteger(quantity) || quantity < 1) { setError(t('editor.quantityInvalid')); return; }
    const payload = { title: values.title.trim(), description: values.description.trim(), price, condition: values.condition, categoryId: values.categoryId, quantity, ...(isEdit ? { status: values.status } : {}) };
    setBusy(true); try {
      if (product) { await api.patch(`/products/${product.id}`, payload); }
      else { const body = new FormData(); for (const [key, value] of Object.entries(payload)) body.set(key, String(value)); if (file) body.set('image', file); const created = await api.post<{ id: string }>('/products', body); await invalidateListings(); navigate(path(pathsFor.product(created.id))); return; }
      await invalidateListings(); navigate(path(pathsFor.product(product.id)));
    } catch (cause) { if (cause instanceof ApiError && cause.status === 401) navigate(path(paths.login)); else setError(t('editor.error')); } finally { setBusy(false); }
  }
  async function invalidateListings() { await Promise.all([client.invalidateQueries({ queryKey: ['public', 'products'] }), client.invalidateQueries({ queryKey: userKey(userId, 'products') })]); }
  async function remove() { if (!product) return; setBusy(true); setError(''); try { await api.patch(`/products/${product.id}/delete`); await invalidateListings(); setConfirmDelete(false); navigate(path(paths.explore)); } catch (cause) { if (cause instanceof ApiError && cause.status === 401) navigate(path(paths.login)); else setError(t('editor.error')); } finally { setBusy(false); } }

  return <section className="marketplace">
    <PageHeader title={t(isEdit ? 'editor.edit' : 'editor.create')} />
    <Surface><form className="market-filters" onSubmit={(event) => void save(event)}>
      <Input label={t('editor.title')} required minLength={3} maxLength={100} value={values.title} onChange={(event) => change('title', event.currentTarget.value)} />
      <TextArea label={t('editor.description')} required minLength={10} maxLength={5000} rows={6} value={values.description} onChange={(event) => change('description', event.currentTarget.value)} />
      <Input label={t('editor.price')} required inputMode="decimal" value={values.price} onChange={(event) => change('price', event.currentTarget.value)} />
      <Select label={t('editor.condition')} value={values.condition} onChange={(event) => { if (isCondition(event.currentTarget.value)) change('condition', event.currentTarget.value); }}><option value="NEW">{t('catalog.new')}</option><option value="USED">{t('catalog.used')}</option></Select>
      <Select label={t('editor.category')} required value={values.categoryId} onChange={(event) => change('categoryId', event.currentTarget.value)}><option value="">{t('editor.selectCategory')}</option>{flatten(categories).map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}</Select>
      <Input label={t('editor.quantity')} required type="number" min={1} step={1} value={values.quantity} onChange={(event) => change('quantity', event.currentTarget.value)} />
      {isEdit && <Select label={t('editor.status')} value={values.status} onChange={(event) => { if (isEditableStatus(event.currentTarget.value)) change('status', event.currentTarget.value); }}><option value="ACTIVE">{t('editor.active')}</option><option value="PAUSED">{t('editor.paused')}</option></Select>}
      {!isEdit && <Input label={t('editor.image')} required type="file" accept="image/jpeg,image/png,image/webp,image/gif" onChange={(event) => setFile(event.currentTarget.files?.[0] ?? null)} />}
      <Button type="submit" disabled={busy} pending={busy}>{t(isEdit ? 'editor.update' : 'editor.submit')}</Button>{isEdit && <Button variant="danger" type="button" disabled={busy} onClick={() => setConfirmDelete(true)}>{t('editor.delete')}</Button>}
      {error && <p role="alert">{error}</p>}
    </form></Surface>
    <div className="market-confirm-dialog"><Dialog open={confirmDelete} onClose={() => setConfirmDelete(false)} title={t('editor.delete')} actions={<><Button variant="secondary" disabled={busy} onClick={() => setConfirmDelete(false)}>{t('common.cancel')}</Button><Button variant="danger" disabled={busy} pending={busy} onClick={() => void remove()}>{t('common.delete')}</Button></>}>{t('editor.deleteConfirm')}</Dialog></div>
  </section>;
}

export function ErrorBoundary() { const error = useRouteError(); const { t } = useI18n(catalogs); return <section className="marketplace"><ErrorState error={new Error(isRouteErrorResponse(error) ? t('product.notFound') : t('editor.error'))} /></section>; }
