import { useState, type FormEvent } from 'react';
import { Link } from 'react-router';
import { useSession, RequireAuth } from '../../core/session';
import { useI18n } from '../../core/locale';
import { usePostSearch } from './queries';
import { PostCard } from './post-card';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };
function SearchPage() {
  const session = useSession(); const { t, path } = useI18n(catalogs); const [input, setInput] = useState(''); const [query, setQuery] = useState(''); const [filter, setFilter] = useState<'all' | 'following' | 'followers'>('all'); const results = usePostSearch(session.user?.id ?? '', query, filter);
  function submit(event: FormEvent) { event.preventDefault(); setQuery(input.trim()); }
  const posts = results.data?.pages.flatMap((page) => page.items) ?? [];
  return <main className="mx-auto grid max-w-3xl gap-5 px-4 py-6 text-ink"><header className="page-header"><h1>{t('social.search.title')}</h1><Link className="ui-button ui-secondary" to={path('feed')}>{t('common.back')}</Link></header>
    <form className="surface grid gap-4 sm:grid-cols-[1fr_auto]" onSubmit={submit}><label className="ui-field">{t('social.search.placeholder')}<input type="search" value={input} maxLength={200} onChange={(event) => setInput(event.currentTarget.value)} /></label><button className="ui-button ui-primary self-end" type="submit">{t('common.search')}</button><label className="ui-field sm:col-span-2">{t('social.search.filter')}<select value={filter} onChange={(event) => setFilter(event.currentTarget.value as typeof filter)}><option value="all">{t('social.search.all')}</option><option value="following">{t('social.search.following')}</option><option value="followers">{t('social.search.followers')}</option></select></label></form>
    {results.isPending && query ? <div className="loading-list" aria-label={t('common.loading')}><span /><span /></div> : results.isError ? <section role="alert" className="error-state"><p>{t('common.error')}</p><button className="ui-button ui-secondary" onClick={() => void results.refetch()}>{t('common.retry')}</button></section> : query && !posts.length ? <section className="empty-state">{t('social.empty.search')}</section> : posts.length ? <section className="grid gap-4">{posts.map((post) => <PostCard key={post.id} post={post} />)}</section> : null}
    {results.hasNextPage ? <button className="ui-button ui-secondary justify-self-center" disabled={results.isFetchingNextPage} onClick={() => void results.fetchNextPage()}>{t('social.loadMore')}</button> : null}
    {results.isFetchNextPageError ? <button className="ui-button ui-secondary" onClick={() => void results.fetchNextPage()}>{t('common.retry')}</button> : null}
  </main>;
}
export default function PostSearchRoute() { return <RequireAuth><SearchPage /></RequireAuth>; }
