import { Link, useLoaderData } from 'react-router';
import { useI18n, useLocale } from '../../core/locale';
import { paths } from '../../core/routes';
import { getCategories } from './server.server';
import type { Category } from './types';
import { PageHeader, Surface } from '../../components';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';
import { PageSection } from '../../components/page-section';
import { RouteErrorBoundary } from '../../components/route-error-boundary';

export async function loader() {
  return getCategories();
}
function CategoryBranch({
  categories,
  path,
}: {
  categories: Category[];
  path: (value?: string) => string;
}) {
  return (
    <ul className="grid list-none grid-cols-[repeat(auto-fit,minmax(12rem,1fr))] gap-4 p-0">
      {categories.map((category) => (
        <li key={category.id}>
          <Surface tone="base">
            <Link to={`${path(paths.explore)}?categoryId=${encodeURIComponent(category.id)}`}>
              {category.name}
            </Link>
            {category.children?.length ? (
              <CategoryBranch categories={category.children} path={path} />
            ) : null}
          </Surface>
        </li>
      ))}
    </ul>
  );
}
export default function CategoriesRoute() {
  const { categories } = useLoaderData<typeof loader>();
  const { path } = useLocale();
  const { t } = useI18n({ en, 'pt-BR': pt });
  return (
    <PageSection className="py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5">
      <PageHeader title={t('catalog.category')} />
      <CategoryBranch categories={categories} path={path} />
    </PageSection>
  );
}
export function ErrorBoundary() {
  return <RouteErrorBoundary catalogs={{ en, 'pt-BR': pt }} />;
}
