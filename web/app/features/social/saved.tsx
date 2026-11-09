import { buttonClass } from '../../components';
import { Link } from 'react-router';
import { useSession, RequireAuth } from '../../core/session';
import { useI18n } from '../../core/locale';
import { useSavedPosts } from './queries';
import { PostCard } from './post-card';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };
function SavedPage() {
  const session = useSession();
  const { t, path } = useI18n(catalogs);
  const query = useSavedPosts(session.user?.id ?? '');
  const posts = query.data?.pages.flatMap((page) => page.items) ?? [];
  return (
    <main className="mx-auto grid max-w-3xl gap-5 px-4 py-6 text-ink">
      <header className="flex items-center justify-between gap-5 [&_h1]:m-0 [&_h1]:font-display [&_h1]:text-[34px] [&_h1]:font-bold">
        <h1>{t('social.saved.title')}</h1>
        <Link className={buttonClass('secondary')} to={path('feed')}>
          {t('common.back')}
        </Link>
      </header>
      {query.isPending ? (
        <div
          className="grid gap-3 [&>span]:h-14 [&>span]:animate-[shimmer_1000ms_linear_infinite_alternate] [&>span]:bg-surface-mid"
          aria-label={t('common.loading')}
        >
          <span />
          <span />
          <span />
        </div>
      ) : query.isError ? (
        <section
          role="alert"
          className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center"
        >
          <p>{t('common.error')}</p>
          <button className={buttonClass('secondary')} onClick={() => void query.refetch()}>
            {t('common.retry')}
          </button>
        </section>
      ) : !posts.length ? (
        <section className="border border-(--hairline) bg-surface p-8 text-center">
          {t('social.empty.saved')}
        </section>
      ) : (
        <section className="grid gap-4">
          {posts.map((post) => (
            <PostCard key={post.id} post={post} />
          ))}
        </section>
      )}
      {query.hasNextPage ? (
        <button
          className={`${buttonClass('secondary')} justify-self-center`}
          disabled={query.isFetchingNextPage}
          onClick={() => void query.fetchNextPage()}
        >
          {t('social.loadMore')}
        </button>
      ) : null}
      {query.isFetchNextPageError ? (
        <button className={buttonClass('secondary')} onClick={() => void query.fetchNextPage()}>
          {t('common.retry')}
        </button>
      ) : null}
    </main>
  );
}
export default function SavedRoute() {
  return (
    <RequireAuth>
      <SavedPage />
    </RequireAuth>
  );
}
