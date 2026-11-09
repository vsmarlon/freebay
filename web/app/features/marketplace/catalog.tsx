import { useCallback, useMemo, useState } from 'react';
import {
  Form,
  Link,
  useFetcher,
  useLoaderData,
  useLocation,
  useNavigate,
  useNavigation,
  type LoaderFunctionArgs,
} from 'react-router';
import { PageSection } from '../../components/page-section';
import { RouteErrorBoundary } from '../../components/route-error-boundary';
import { useLocale, useI18n } from '../../core/locale';
import { paths } from '../../core/routes';
import { formatListingPriceInput, parseListingPrice } from './listing-input';
import { appendPage, catalogQuery, type CatalogFilters } from './queries';
import { getCategories, getProducts } from './server.server';
import { ProductGrid } from './product-card';
import type { Category, ProductPage } from './types';
import {
  Button,
  Empty,
  IconButton,
  Input,
  Loading,
  PageHeader,
  Select,
  Surface,
} from '../../components';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';
import { Icon } from '../../components';

const catalogs = { en, 'pt-BR': pt };
type LoaderData = { page: ProductPage; categories: Category[]; filters: CatalogFilters };
export async function loader({ request }: LoaderFunctionArgs): Promise<LoaderData> {
  const params = new URL(request.url).searchParams;
  const filters: CatalogFilters = {
    q: params.get('q') ?? '',
    categoryId: params.get('categoryId') ?? '',
    minPrice: params.get('minPrice') ?? '',
    maxPrice: params.get('maxPrice') ?? '',
    condition: params.get('condition') ?? '',
    sort: params.get('sort') ?? 'recent',
    cursor: params.get('cursor') ?? undefined,
  };
  const query = catalogQuery(filters);
  const [page, categoryResult] = await Promise.all([getProducts(query), getCategories()]);
  return { page, categories: categoryResult.categories, filters };
}

function flatten(categories: Category[]): Category[] {
  return categories.flatMap((category) => [category, ...flatten(category.children ?? [])]);
}
export default function CatalogRoute() {
  const { page, categories, filters } = useLoaderData<LoaderData>();
  const { locale, path } = useLocale();
  const { t } = useI18n(catalogs);
  const location = useLocation();
  const navigate = useNavigate();
  const navigation = useNavigation();
  const fetcher = useFetcher<LoaderData>();
  const [products, setProducts] = useState(page);
  const [prevPage, setPrevPage] = useState(page);
  if (page !== prevPage) {
    setProducts(page);
    setPrevPage(page);
  }
  const [filterError, setFilterError] = useState('');
  const appendRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (node && fetcher.data?.page)
        setProducts((current) => appendPage(current, fetcher.data!.page));
    },
    [fetcher.data],
  );
  const options = useMemo(() => flatten(categories), [categories]);
  const loading = navigation.state !== 'idle';
  const isSearch = location.pathname.endsWith('/search');
  return (
    <PageSection className="space-y-4">
      <div ref={appendRef} className="sr-only" aria-hidden />
      <PageHeader
        title={t('catalog.title')}
        actions={
          <>
            <Link
              className="grid size-[38px] place-items-center border border-ink bg-surface-mid p-0 text-ink text-[15px] focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2 max-sm:size-[34px]"
              to={path(paths.myProducts)}
              aria-label={t('myProducts.title')}
              title={t('myProducts.title')}
            >
              <Icon name="box" />
            </Link>
            <Link
              className="grid size-[38px] place-items-center border border-ink bg-surface-mid p-0 text-ink text-[15px] focus-visible:outline-2 focus-visible:outline-brand focus-visible:outline-offset-2 max-sm:size-[34px]"
              to={path(paths.favorites)}
              aria-label={t('favorites.title')}
              title={t('favorites.title')}
            >
              <Icon name="heart" />
            </Link>
            <IconButton
              aria-label={t('catalog.sell')}
              title={t('catalog.sell')}
              onClick={() => navigate(path(paths.sell))}
            >
              <Icon name="sell" />
            </IconButton>
          </>
        }
      />
      {isSearch && (
        <nav className="flex gap-4" aria-label={t('catalog.searchTabs')}>
          <Link
            aria-current="page"
            to={`${path(paths.search)}${filters.q ? `?q=${encodeURIComponent(filters.q)}` : ''}`}
          >
            {t('catalog.productsTab')}
          </Link>
          <Link
            to={`${path(`${paths.search}/posts`)}${filters.q ? `?q=${encodeURIComponent(filters.q)}` : ''}`}
          >
            {t('catalog.postsTab')}
          </Link>
          <Link
            to={`${path(`${paths.search}/people`)}${filters.q ? `?q=${encodeURIComponent(filters.q)}` : ''}`}
          >
            {t('catalog.peopleTab')}
          </Link>
        </nav>
      )}
      <Surface tone="base">
        <Form
          className="grid grid-cols-[repeat(auto-fit,minmax(min(100%,10rem),1fr))] gap-4"
          method="get"
          onSubmit={(event) => {
            event.preventDefault();
            setFilterError('');
            const form = new FormData(event.currentTarget);
            const params = new URLSearchParams();
            for (const key of ['q', 'categoryId', 'condition', 'sort']) {
              const value = String(form.get(key) ?? '');
              if (value) params.set(key, value);
            }
            try {
              for (const key of ['minPrice', 'maxPrice']) {
                const value = String(form.get(key) ?? '').trim();
                if (value) {
                  const cents = parseListingPrice(value, locale, true);
                  params.set(key, String(cents));
                }
              }
              navigate(`${location.pathname}?${params}`);
            } catch {
              setFilterError(t('catalog.priceInvalid'));
            }
          }}
        >
          <Input
            label={t('catalog.search')}
            type="search"
            name="q"
            maxLength={200}
            defaultValue={filters.q}
          />
          <Select label={t('catalog.category')} name="categoryId" defaultValue={filters.categoryId}>
            <option value="">{t('catalog.anyCategory')}</option>
            {options.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </Select>
          <Select label={t('catalog.condition')} name="condition" defaultValue={filters.condition}>
            <option value="">{t('catalog.anyCondition')}</option>
            <option value="NEW">{t('catalog.new')}</option>
            <option value="USED">{t('catalog.used')}</option>
          </Select>
          <Input
            label={t('catalog.minPrice')}
            name="minPrice"
            inputMode="decimal"
            defaultValue={
              filters.minPrice ? formatListingPriceInput(Number(filters.minPrice), locale) : ''
            }
          />
          <Input
            label={t('catalog.maxPrice')}
            name="maxPrice"
            inputMode="decimal"
            defaultValue={
              filters.maxPrice ? formatListingPriceInput(Number(filters.maxPrice), locale) : ''
            }
          />
          <Select label={t('catalog.sort')} name="sort" defaultValue={filters.sort}>
            <option value="recent">{t('catalog.recent')}</option>
            <option value="price_asc">{t('catalog.priceAsc')}</option>
            <option value="price_desc">{t('catalog.priceDesc')}</option>
            <option value="popular">{t('catalog.popular')}</option>
          </Select>
          <Button type="submit">{t('common.search')}</Button>
          {filterError && <p role="alert">{filterError}</p>}
        </Form>
      </Surface>
      {loading ? (
        <Loading label={t('common.loading')} />
      ) : products.products.length ? (
        <ProductGrid products={products.products} />
      ) : (
        <Empty title={t('catalog.noResults')} />
      )}
      {products.nextCursor && (
        <Button
          variant="secondary"
          disabled={fetcher.state !== 'idle'}
          onClick={() => {
            const params = new URLSearchParams(location.search);
            params.set('cursor', products.nextCursor!);
            fetcher.load(`${location.pathname}?${params}`);
          }}
        >
          {fetcher.state === 'idle' ? t('catalog.loadMore') : t('common.loading')}
        </Button>
      )}
    </PageSection>
  );
}

export function ErrorBoundary() {
  return <RouteErrorBoundary catalogs={catalogs} />;
}
