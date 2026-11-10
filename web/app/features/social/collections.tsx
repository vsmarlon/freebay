import { Link, useLocation } from 'react-router';
import { RequireAuth, useSession } from '../../core/session';
import { useI18n } from '../../core/locale';
import { useLikedPosts, useMyPosts } from './queries';
import { PostCard } from './post-card';
import { Empty, buttonClass } from '../../components';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };

function CollectionPage() {
  const { pathname } = useLocation();
  const isLiked = pathname.endsWith('/liked');
  const { user } = useSession();
  const { t, path } = useI18n(catalogs);
  const userId = user?.id ?? '';
  const liked = useLikedPosts(userId);
  const own = useMyPosts(userId);
  const posts = isLiked
    ? (liked.data ?? [])
    : (own.data?.pages.flatMap((page) => page.items.map((entry) => entry.post)) ?? []);
  const query = isLiked ? liked : own;
  return (
    <main className="mx-auto grid max-w-5xl gap-5 px-4 py-6 text-ink">
      <Link className="font-bold text-brand" to={path('feed')}>
        ← {t('common.back')}
      </Link>
      <h1 className="font-display text-3xl font-bold">
        {t(isLiked ? 'social.collection.liked' : 'social.collection.mine')}
      </h1>
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
          className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center"
          role="alert"
        >
          <p>{t('common.error')}</p>
          <button className={buttonClass('secondary')} onClick={() => void query.refetch()}>
            {t('common.retry')}
          </button>
        </section>
      ) : !posts.length ? (
        <Empty
          title={t(isLiked ? 'social.collection.emptyLiked' : 'social.collection.emptyMine')}
          action={
            <Link className={buttonClass('secondary')} to={path('explore')}>
              {t('nav.explore')}
            </Link>
          }
        />
      ) : (
        <div className="grid grid-cols-2 items-start gap-4 [&>article]:h-full [&>article]:transition-colors [&>article]:duration-180 [&>article:hover]:border-(--edge)">
          {posts.map((post) => (
            <PostCard key={post.id} post={post} />
          ))}
        </div>
      )}
      {!isLiked && own.hasNextPage ? (
        <button
          className={`${buttonClass('secondary')} justify-self-center`}
          disabled={own.isFetchingNextPage}
          onClick={() => void own.fetchNextPage()}
        >
          {own.isFetchingNextPage ? t('common.loading') : t('common.loadMore')}
        </button>
      ) : null}
    </main>
  );
}

export default function SocialCollectionRoute() {
  return (
    <RequireAuth>
      <CollectionPage />
    </RequireAuth>
  );
}
