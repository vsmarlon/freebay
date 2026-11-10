import { useState } from 'react';
import { Dialog } from '../../../components';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';

export type ProductCard = { id: string; title: string; price: number; imageUrl: string | null };

export function ProductPickerDialog({
  products,
  onClose,
  onSend,
}: {
  products: ProductCard[];
  onClose: () => void;
  onSend: (product: ProductCard) => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const [query, setQuery] = useState('');
  const normalizedQuery = query.toLocaleLowerCase();
  return (
    <Dialog open onClose={onClose} title={t('chat.shareProduct')}>
      <input
        className="min-h-10 w-full bg-surface-high p-2"
        aria-label={t('chat.searchProducts')}
        value={query}
        onChange={(event) => setQuery(event.currentTarget.value)}
        type="search"
      />
      {products
        .filter((product) => product.title.toLocaleLowerCase().includes(normalizedQuery))
        .map((product) => (
          <button
            key={product.id}
            type="button"
            className="block w-full bg-surface-mid p-3 text-left"
            onClick={() => onSend(product)}
          >
            {product.title}
          </button>
        ))}
      {!products.length ? <p role="status">{t('chat.noProducts')}</p> : null}
    </Dialog>
  );
}
