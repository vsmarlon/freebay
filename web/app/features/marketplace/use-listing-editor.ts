import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router';
import { useQueryClient } from '@tanstack/react-query';
import { ApiError } from '../../core/api';
import { useLocale, useI18n } from '../../core/locale';
import { paths, pathsFor } from '../../core/routes';
import { userKey } from '../../core/query-client';
import { mediaUrl } from '../../core/media';
import { formatMoney } from '../../core/money';
import { useSession } from '../../core/session';
import { productEditorApi } from './api';
import { formatListingPriceInput, parseListingPrice, validateProductImage } from './listing-input';
import type { ProductSummary } from './types';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };

export type FormValues = {
  title: string;
  description: string;
  price: string;
  condition: 'NEW' | 'USED';
  categoryId: string;
  quantity: string;
  status: 'ACTIVE' | 'PAUSED';
};

function initial(product: ProductSummary | null, locale: 'pt-BR' | 'en'): FormValues {
  return {
    title: product?.title ?? '',
    description: product?.description ?? '',
    price: product ? formatListingPriceInput(product.price, locale) : '',
    condition: product?.condition ?? 'USED',
    categoryId: product?.categoryId ?? '',
    quantity: String(product?.quantity ?? 1),
    status: product?.status === 'PAUSED' ? 'PAUSED' : 'ACTIVE',
  };
}

export function useListingEditor(product: ProductSummary | null) {
  const { user } = useSession();
  const { locale, path } = useLocale();
  const { t } = useI18n(catalogs);
  const navigate = useNavigate();
  const client = useQueryClient();
  const [values, setValues] = useState(() => initial(product, locale));
  const [prevKey, setPrevKey] = useState(`${product?.id ?? ''}:${locale}`);
  if (`${product?.id ?? ''}:${locale}` !== prevKey) {
    setValues(initial(product, locale));
    setPrevKey(`${product?.id ?? ''}:${locale}`);
  }
  const [files, setFiles] = useState<File[]>([]);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const previews = useMemo(() => files.map((file) => URL.createObjectURL(file)), [files]);
  const isEdit = product !== null;
  const previewUrls = isEdit
    ? (product?.images ?? []).map((image) => mediaUrl(image.url))
    : previews;
  const cover = previewUrls[0];

  // Object URLs live as long as the file selection that created them.
  useEffect(() => () => previews.forEach((url) => URL.revokeObjectURL(url)), [previews]);
  const userId = user?.id ?? '';

  function change<K extends keyof FormValues>(key: K, value: FormValues[K]) {
    setValues((current) => ({ ...current, [key]: value }));
  }
  function addFiles(selected: FileList | null) {
    setError('');
    if (!selected) return;
    const picked = Array.from(selected);
    if (files.length + picked.length > 10) {
      setError(t('editor.tooManyImages'));
      return;
    }
    if (picked.some((file) => validateProductImage(file) !== null)) {
      setError(t('editor.imageTypes'));
      return;
    }
    setFiles((current) => [...current, ...picked]);
  }
  function removeImage(index: number) {
    setFiles((current) => current.filter((_, fileIndex) => fileIndex !== index));
  }
  async function invalidateListings() {
    await Promise.all([
      client.invalidateQueries({ queryKey: ['public', 'products'] }),
      client.invalidateQueries({ queryKey: userKey(userId, 'products') }),
    ]);
  }
  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError('');
    if (!isEdit && files.length === 0) {
      setError(t('editor.requiredImage'));
      return;
    }
    let price: number;
    try {
      price = parseListingPrice(values.price, locale);
    } catch {
      setError(t('editor.invalidPrice'));
      return;
    }
    const quantity = Number(values.quantity);
    if (!Number.isSafeInteger(quantity) || quantity < 1) {
      setError(t('editor.quantityInvalid'));
      return;
    }
    const payload = {
      title: values.title.trim(),
      description: values.description.trim(),
      price,
      condition: values.condition,
      categoryId: values.categoryId,
      quantity,
      ...(isEdit ? { status: values.status } : {}),
    };
    setBusy(true);
    try {
      if (product) {
        await productEditorApi.update(product.id, payload);
      } else {
        const body = new FormData();
        for (const [key, value] of Object.entries(payload)) body.set(key, String(value));
        for (const file of files) body.append('files', file);
        body.set(
          'mediaMetadata',
          JSON.stringify(files.map((_, fileIndex) => ({ fileIndex, type: 'IMAGE', hotspots: [] }))),
        );
        const created = await productEditorApi.create(body);
        await invalidateListings();
        navigate(path(pathsFor.product(created.id)));
        return;
      }
      await invalidateListings();
      navigate(path(pathsFor.product(product.id)));
    } catch (cause) {
      if (cause instanceof ApiError && cause.status === 401) navigate(path(paths.login));
      else setError(t('editor.error'));
    } finally {
      setBusy(false);
    }
  }
  async function remove() {
    if (!product) return;
    setBusy(true);
    setError('');
    try {
      await productEditorApi.remove(product.id);
      await invalidateListings();
      setConfirmDelete(false);
      navigate(path(paths.explore));
    } catch (cause) {
      if (cause instanceof ApiError && cause.status === 401) navigate(path(paths.login));
      else setError(t('editor.error'));
    } finally {
      setBusy(false);
    }
  }

  let priceLabel = '—';
  try {
    priceLabel = formatMoney(parseListingPrice(values.price, locale), locale);
  } catch {
    /* incomplete price input keeps the dash */
  }
  const quantityPreview = Math.max(1, Number(values.quantity) || 1);

  return {
    t,
    values,
    change,
    files,
    previews,
    error,
    busy,
    confirmDelete,
    setConfirmDelete,
    addFiles,
    removeImage,
    save,
    remove,
    isEdit,
    priceLabel,
    quantityPreview,
    previewUrls,
    cover,
  };
}

export type ListingEditorState = ReturnType<typeof useListingEditor>;
