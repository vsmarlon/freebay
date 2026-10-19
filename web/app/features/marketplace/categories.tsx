import { Link, useLoaderData } from 'react-router';
import { useI18n, useLocale } from '../../core/locale';
import { paths } from '../../core/routes';
import { getCategories } from './server.server';
import type { Category } from './types';
import { Button, ErrorState, PageHeader, Surface } from '../../components';
import en from './catalogs/en.json'; import pt from './catalogs/pt-BR.json';
import './marketplace.css';

export async function loader() { return getCategories(); }
function CategoryBranch({ categories, path }: { categories: Category[]; path: (value?: string) => string }) {
  return <ul className="market-category-list">{categories.map((category) => <li key={category.id}><Surface tone="base"><Link to={`${path(paths.explore)}?categoryId=${encodeURIComponent(category.id)}`}>{category.name}</Link>{category.children?.length ? <CategoryBranch categories={category.children} path={path} /> : null}</Surface></li>)}</ul>;
}
export default function CategoriesRoute() { const { categories } = useLoaderData<typeof loader>(); const { path } = useLocale(); const { t } = useI18n({ en, 'pt-BR': pt }); return <section className="marketplace"><PageHeader title={t('catalog.category')} /><CategoryBranch categories={categories} path={path} /></section>; }
export function ErrorBoundary() { const { t } = useI18n({ en, 'pt-BR': pt }); return <section className="marketplace"><ErrorState error={new Error(t('common.error'))} /><Button variant="secondary" onClick={() => window.location.reload()}>{t('common.retry')}</Button></section>; }
