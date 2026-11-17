import { useState } from 'react';
import { Link } from 'react-router';
import { buttonClass } from '../../components';
import { useSession, RequireAuth } from '../../core/session';
import { useI18n } from '../../core/locale';
import { StoryRail } from '../stories';
import { useFeed } from './queries';
import { PostCard } from './post-card';
import { CreatePost } from './create-post';
import type { ContentFilter, FeedType } from './types';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };

function FeedPage() {
  const session = useSession();
  const { t, path } = useI18n(catalogs);
  const userId = session.user?.id ?? '';
  const [type, setType] = useState<FeedType>('explore');
  const [filter, setFilter] = useState<ContentFilter>('all');
  const feed = useFeed(userId, type, filter);
  const posts = feed.data?.pages.flatMap((page) => page.posts) ?? [];
  return (
    <main className="mx-auto max-w-[1320px] px-4 py-6 text-ink lg:px-8">
      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_300px]">
        <section className="grid min-w-0 content-start gap-5">
          <nav aria-label={t('social.feed.title')} className="flex flex-wrap gap-2">
            <button
              className={buttonClass(type === 'explore' ? 'primary' : 'secondary')}
              aria-pressed={type === 'explore'}
              onClick={() => setType('explore')}
            >
              {t('social.feed.explore')}
            </button>
            <button
              className={buttonClass(type === 'following' ? 'primary' : 'secondary')}
              aria-pressed={type === 'following'}
              onClick={() => setType('following')}
            >
              {t('social.feed.following')}
            </button>
          </nav>
          <div className="border border-(--hairline) bg-surface p-4 lg:hidden">
            <StoryRail />
          </div>
          <nav aria-label={t('social.feed.typeFilter')} className="flex gap-2 overflow-x-auto">
            {(['all', 'social', 'selling'] as const).map((value) => (
              <button
                key={value}
                className={buttonClass('ghost', 'sm')}
                aria-pressed={filter === value}
                onClick={() => setFilter(value)}
              >
                {t(`social.filter.${value}`)}
              </button>
            ))}
          </nav>
          <CreatePost userId={userId} />
          {feed.isPending ? (
            <div
              className="grid gap-3 [&>span]:h-14 [&>span]:animate-[shimmer_1000ms_linear_infinite_alternate] [&>span]:bg-surface-mid"
              aria-label={t('common.loading')}
            >
              <span />
              <span />
              <span />
            </div>
          ) : feed.isError ? (
            <section
              role="alert"
              className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center"
            >
              <p>{t('common.error')}</p>
              <button className={buttonClass('secondary')} onClick={() => void feed.refetch()}>
                {t('common.retry')}
              </button>
            </section>
          ) : posts.length === 0 ? (
            <section className="border border-(--hairline) bg-surface p-8 text-center">
              {t('social.empty.feed')}
            </section>
          ) : (
            <div className="grid gap-4">
              {posts.map((post) => (
                <PostCard key={post.id} post={post} />
              ))}
            </div>
          )}
          {feed.hasNextPage ? (
            <button
              className={`${buttonClass('secondary')} justify-self-center`}
              disabled={feed.isFetchingNextPage}
              onClick={() => void feed.fetchNextPage()}
            >
              {feed.isFetchingNextPage ? t('common.loading') : t('social.loadMore')}
            </button>
          ) : null}
          {feed.isFetchNextPageError ? (
            <button
              className={`${buttonClass('secondary')} justify-self-center`}
              onClick={() => void feed.fetchNextPage()}
            >
              {t('common.retry')}
            </button>
          ) : null}
        </section>
        <aside className="hidden content-start gap-6 lg:grid">
          <div className="border border-(--hairline) bg-surface p-4">
            <StoryRail />
          </div>
          <section className="border border-(--hairline) bg-surface p-4 grid gap-3">
            <h2 className="font-display text-xl font-bold">{t('social.search.title')}</h2>
            <Link className={buttonClass('secondary')} to={path('search/posts')}>
              {t('common.search')} ↗
            </Link>
            <Link className={buttonClass('ghost')} to={path('saved')}>
              {t('social.saved.title')}
            </Link>
            <Link className={buttonClass('ghost')} to={path('liked')}>
              {t('social.collection.liked')}
            </Link>
            <Link className={buttonClass('ghost')} to={path('posts/mine')}>
              {t('social.collection.mine')}
            </Link>
          </section>
        </aside>
      </div>
    </main>
  );
}

export default function FeedRoute() {
  return (
    <RequireAuth>
      <FeedPage />
    </RequireAuth>
  );
}
