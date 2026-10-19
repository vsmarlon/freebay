import { Link, useLocation } from 'react-router';
import { RequireAuth, useSession } from '../../core/session';
import { useI18n } from '../../core/locale';
import { useLikedPosts, useMyPosts } from './queries';
import { PostCard } from './post-card';
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
  const posts = isLiked ? liked.data ?? [] : own.data?.pages.flatMap((page) => page.items.map((entry) => entry.post)) ?? [];
  const query = isLiked ? liked : own;
  return <main className="mx-auto grid max-w-4xl gap-5 px-4 py-6 text-ink">
    <Link className="font-bold text-brand" to={path('feed')}>← {t('common.back')}</Link>
    <h1 className="font-display text-3xl font-bold">{t(isLiked ? 'social.collection.liked' : 'social.collection.mine')}</h1>
    {query.isPending ? <div className="loading-list" aria-label={t('common.loading')}><span /><span /><span /></div> : query.isError ? <section className="error-state" role="alert"><p>{t('common.error')}</p><button className="ui-button ui-secondary" onClick={() => void query.refetch()}>{t('common.retry')}</button></section> : !posts.length ? <section className="empty-state">{t(isLiked ? 'social.collection.emptyLiked' : 'social.collection.emptyMine')}</section> : <div className="grid gap-4">{posts.map((post) => <PostCard key={post.id} post={post} />)}</div>}
    {!isLiked && own.hasNextPage ? <button className="ui-button ui-secondary justify-self-center" disabled={own.isFetchingNextPage} onClick={() => void own.fetchNextPage()}>{own.isFetchingNextPage ? t('common.loading') : t('common.loadMore')}</button> : null}
  </main>;
}

export default function SocialCollectionRoute() { return <RequireAuth><CollectionPage /></RequireAuth>; }
