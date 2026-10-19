import { Link } from 'react-router';
import { useSession, RequireAuth } from '../../core/session';
import { useI18n } from '../../core/locale';
import { useSavedPosts } from './queries';
import { PostCard } from './post-card';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };
function SavedPage() {
  const session = useSession(); const { t, path } = useI18n(catalogs); const query = useSavedPosts(session.user?.id ?? ''); const posts = query.data?.pages.flatMap((page) => page.posts) ?? [];
  return <main className="mx-auto grid max-w-3xl gap-5 px-4 py-6 text-ink"><header className="page-header"><h1>{t('social.saved.title')}</h1><Link className="ui-button ui-secondary" to={path('feed')}>{t('common.back')}</Link></header>
    {query.isPending ? <div className="loading-list" aria-label={t('common.loading')}><span /><span /><span /></div> : query.isError ? <section role="alert" className="error-state"><p>{t('common.error')}</p><button className="ui-button ui-secondary" onClick={() => void query.refetch()}>{t('common.retry')}</button></section> : !posts.length ? <section className="empty-state">{t('social.empty.saved')}</section> : <section className="grid gap-4">{posts.map((post) => <PostCard key={post.id} post={post} />)}</section>}
    {query.hasNextPage ? <button className="ui-button ui-secondary justify-self-center" disabled={query.isFetchingNextPage} onClick={() => void query.fetchNextPage()}>{t('social.loadMore')}</button> : null}
    {query.isFetchNextPageError ? <button className="ui-button ui-secondary" onClick={() => void query.fetchNextPage()}>{t('common.retry')}</button> : null}
  </main>;
}
export default function SavedRoute() { return <RequireAuth><SavedPage /></RequireAuth>; }
