import { useLoaderData, useNavigate, type LoaderFunctionArgs } from 'react-router';
import { PageSection } from '../../components/page-section';
import { RouteErrorBoundary } from '../../components/route-error-boundary';
import { Button, Dialog, ErrorState, Loading, PageHeader, Surface } from '../../components';
import { useSession } from '../../core/session';
import { useLocale } from '../../core/locale';
import { paths } from '../../core/routes';
import type { Category, ProductSummary } from './types';
import { getCategories, getProduct } from './server.server';
import { ListingEditorForm } from './listing-editor-form';
import { ListingEditorPreview } from './listing-editor-preview';
import { useListingEditor } from './use-listing-editor';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };
type LoaderData = { product: ProductSummary | null; categories: Category[] };

export async function loader({ params }: LoaderFunctionArgs): Promise<LoaderData> {
  const categoryResult = await getCategories();
  return {
    categories: categoryResult.categories,
    product: params.id ? (await getProduct(params.id)).product : null,
  };
}

export default function ListingEditorRoute() {
  const { product, categories } = useLoaderData<LoaderData>();
  const { user, isPending } = useSession();
  const { path } = useLocale();
  const navigate = useNavigate();
  const editor = useListingEditor(product);
  const { t, busy, confirmDelete, setConfirmDelete, remove } = editor;

  if (isPending)
    return (
      <PageSection>
        <Loading label={t('common.loading')} />
      </PageSection>
    );
  if (!user)
    return (
      <PageSection>
        <Surface>
          <p>{t('auth.required')}</p>
          <Button onClick={() => navigate(path(paths.login))}>{t('auth.signIn')}</Button>
        </Surface>
      </PageSection>
    );
  if (product && product.sellerId !== user.id)
    return (
      <PageSection>
        <ErrorState error={new Error(t('common.error'))} />
      </PageSection>
    );
  if (product?.status === 'SOLD')
    return (
      <PageSection>
        <ErrorState error={new Error(t('editor.soldReadOnly'))} />
      </PageSection>
    );

  return (
    <PageSection>
      <PageHeader title={t(editor.isEdit ? 'editor.edit' : 'editor.create')} />
      <div className="mt-6 grid items-start gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(260px,340px)]">
        <ListingEditorPreview editor={editor} />
        <ListingEditorForm editor={editor} categories={categories} />
      </div>
      <div className="[&_.ui-dialog_footer>button:last-child]:hidden">
        <Dialog
          open={confirmDelete}
          onClose={() => setConfirmDelete(false)}
          title={t('editor.delete')}
          actions={
            <>
              <Button variant="secondary" disabled={busy} onClick={() => setConfirmDelete(false)}>
                {t('common.cancel')}
              </Button>
              <Button variant="danger" disabled={busy} pending={busy} onClick={() => void remove()}>
                {t('common.delete')}
              </Button>
            </>
          }
        >
          {t('editor.deleteConfirm')}
        </Dialog>
      </div>
    </PageSection>
  );
}

export function ErrorBoundary() {
  return (
    <RouteErrorBoundary
      catalogs={catalogs}
      notFoundKey="product.notFound"
      fallbackKey="editor.error"
      showRetry={false}
    />
  );
}
