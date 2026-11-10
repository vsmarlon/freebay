import { Button, ComposerInput, Icon, Input, Select, Surface } from '../../components';
import { QuantityStepper } from '../../components/quantity-stepper';
import type { Category } from './types';
import type { ListingEditorState } from './use-listing-editor';

const galleryClass =
  'm-0 grid list-none grid-cols-[repeat(auto-fill,minmax(96px,1fr))] gap-2 p-0 [&>li]:relative [&>li]:aspect-square [&>li]:bg-surface-high [&_img]:block [&_img]:size-full [&_img]:object-cover [&_button]:absolute [&_button]:right-1 [&_button]:top-1 [&_button]:grid [&_button]:size-[26px] [&_button]:place-items-center [&_button]:border-0 [&_button]:bg-black/80 [&_button]:text-white';

function ImageGallery({
  urls,
  label,
  coverLabel,
  removeLabel,
  onRemove,
}: {
  urls: string[];
  label: string;
  coverLabel: string;
  removeLabel?: string;
  onRemove?: (index: number) => void;
}) {
  if (!urls.length) return null;
  return (
    <ul className={galleryClass}>
      {urls.map((url, index) => (
        <li key={url}>
          <img src={url} alt={`${label} ${index + 1}`} />
          {index === 0 ? (
            <span className="absolute bottom-1 left-1 bg-black/80 px-1.5 py-0.5 text-[10px] uppercase tracking-wide text-white">
              {coverLabel}
            </span>
          ) : null}
          {onRemove ? (
            <button type="button" aria-label={removeLabel} onClick={() => onRemove(index)}>
              <Icon name="close" size={14} />
            </button>
          ) : null}
        </li>
      ))}
    </ul>
  );
}

function flatten(categories: Category[]): Category[] {
  return categories.flatMap((category) => [category, ...flatten(category.children ?? [])]);
}

function isCondition(value: string): value is 'NEW' | 'USED' {
  return value === 'NEW' || value === 'USED';
}

function isEditableStatus(value: string): value is 'ACTIVE' | 'PAUSED' {
  return value === 'ACTIVE' || value === 'PAUSED';
}

export function ListingEditorForm({
  editor,
  categories,
}: {
  editor: ListingEditorState;
  categories: Category[];
}) {
  const {
    t,
    values,
    change,
    previews,
    error,
    busy,
    isEdit,
    addFiles,
    removeImage,
    save,
    previewUrls,
    setConfirmDelete,
  } = editor;

  return (
    <Surface className="order-2 lg:col-start-1 lg:row-start-1">
      <form className="grid gap-4" onSubmit={(event) => void save(event)}>
        <Input
          label={t('editor.title')}
          required
          minLength={3}
          maxLength={100}
          value={values.title}
          onChange={(event) => change('title', event.currentTarget.value)}
        />
        <ComposerInput
          id="editor-description"
          label={t('editor.description')}
          value={values.description}
          maxLength={5000}
          submitOnEnter={false}
          onChange={(value) => change('description', value)}
          textareaProps={{ required: true, minLength: 10 }}
        />
        <Input
          label={t('editor.price')}
          required
          inputMode="decimal"
          value={values.price}
          onChange={(event) => change('price', event.currentTarget.value)}
        />
        <Select
          label={t('editor.condition')}
          value={values.condition}
          onChange={(event) => {
            if (isCondition(event.currentTarget.value))
              change('condition', event.currentTarget.value);
          }}
        >
          <option value="NEW">{t('catalog.new')}</option>
          <option value="USED">{t('catalog.used')}</option>
        </Select>
        <Select
          label={t('editor.category')}
          required
          value={values.categoryId}
          onChange={(event) => change('categoryId', event.currentTarget.value)}
        >
          <option value="">{t('editor.selectCategory')}</option>
          {flatten(categories).map((category) => (
            <option key={category.id} value={category.id}>
              {category.name}
            </option>
          ))}
        </Select>
        <QuantityStepper
          label={t('editor.quantity')}
          increase={t('product.increase')}
          decrease={t('product.decrease')}
          value={editor.quantityPreview}
          max={999}
          disabled={busy}
          onCommit={(next) => change('quantity', String(next))}
        />
        {isEdit && (
          <Select
            label={t('editor.status')}
            value={values.status}
            onChange={(event) => {
              if (isEditableStatus(event.currentTarget.value))
                change('status', event.currentTarget.value);
            }}
          >
            <option value="ACTIVE">{t('editor.active')}</option>
            <option value="PAUSED">{t('editor.paused')}</option>
          </Select>
        )}
        {isEdit ? (
          <div>
            <p className="text-muted">{t('editor.imagesReadOnly')}</p>
            <ImageGallery
              urls={previewUrls}
              label={t('editor.images')}
              coverLabel={t('editor.cover')}
            />
          </div>
        ) : (
          <div>
            <Input
              label={t('editor.images')}
              type="file"
              multiple
              accept="image/jpeg,image/png,image/webp,image/gif"
              hint={t('editor.imagesHint')}
              onChange={(event) => {
                addFiles(event.currentTarget.files);
                event.currentTarget.value = '';
              }}
            />
            <ImageGallery
              urls={previews}
              label={t('editor.images')}
              coverLabel={t('editor.cover')}
              removeLabel={t('editor.removeImage')}
              onRemove={removeImage}
            />
          </div>
        )}
        <Button type="submit" disabled={busy} pending={busy}>
          {t(isEdit ? 'editor.update' : 'editor.submit')}
        </Button>
        {isEdit && (
          <Button
            variant="danger"
            type="button"
            disabled={busy}
            onClick={() => setConfirmDelete(true)}
          >
            {t('editor.delete')}
          </Button>
        )}
        {error && <p role="alert">{error}</p>}
      </form>
    </Surface>
  );
}
