import { Icon } from '../../components';
import type { ListingEditorState } from './use-listing-editor';

export function ListingEditorPreview({ editor }: { editor: ListingEditorState }) {
  const { t, values, cover, previewUrls, priceLabel, quantityPreview } = editor;
  return (
    <aside
      className="order-1 grid gap-3 lg:sticky lg:top-4 lg:col-start-2 lg:row-start-1"
      aria-label={t('editor.preview')}
    >
      <div className="grid gap-2 border-[1.5px] border-edge bg-surface p-4">
        <div className="relative grid aspect-square place-items-center overflow-hidden bg-surface-high text-muted [&_img]:block [&_img]:size-full [&_img]:object-cover">
          {cover ? (
            <img src={cover} alt={values.title.trim() || t('editor.preview')} />
          ) : (
            <Icon name="image" size={40} />
          )}
          {previewUrls.length > 1 ? (
            <span className="absolute bottom-2 right-2 bg-black/80 px-2 py-0.5 text-[11px] text-white">
              +{previewUrls.length - 1}
            </span>
          ) : null}
        </div>
        <h3 className="m-0 font-display text-base font-bold leading-[1.3]">
          {values.title.trim() || '—'}
        </h3>
        <p className="m-0 font-display text-[22px] font-bold">{priceLabel}</p>
        <p className="text-muted">
          {t('editor.quantity')}: {quantityPreview}
        </p>
      </div>
      <p className="text-muted">{t('editor.previewNote')}</p>
    </aside>
  );
}
