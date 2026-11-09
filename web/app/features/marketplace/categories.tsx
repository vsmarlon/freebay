import { Link, useLoaderData } from 'react-router';
import { useI18n, useLocale } from '../../core/locale';
import { paths } from '../../core/routes';
import { getCategories } from './server.server';
import type { Category } from './types';
import { Button, ErrorState, PageHeader, Surface } from '../../components';
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';

export async function loader() { return getCategories(); }
function CategoryBranch({ categories, path }: { categories: Category[]; path: (value?: string) => string }) {
  return <ul className="grid list-none grid-cols-[repeat(auto-fit,minmax(12rem,1fr))] gap-4 p-0">{categories.map((category) => <li key={category.id}><Surface tone="base"><Link to={`${path(paths.explore)}?categoryId=${encodeURIComponent(category.id)}`}>{category.name}</Link>{category.children?.length ? <CategoryBranch categories={category.children} path={path} /> : null}</Surface></li>)}</ul>;
}
export default function CategoriesRoute() { const { categories } = useLoaderData<typeof loader>(); const { path } = useLocale(); const { t } = useI18n({ en, 'pt-BR': pt }); return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><PageHeader title={t('catalog.category')} /><CategoryBranch categories={categories} path={path} /></section>; }
export function ErrorBoundary() { const { t } = useI18n({ en, 'pt-BR': pt }); return <section className="mx-auto w-[min(calc(100%-2rem),80rem)] py-8 pb-20 max-sm:w-[min(calc(100%-1.25rem),80rem)] max-sm:pt-5"><ErrorState error={new Error(t('common.error'))} /><Button variant="secondary" onClick={() => window.location.reload()}>{t('common.retry')}</Button></section>; }
