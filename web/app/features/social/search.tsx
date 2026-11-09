import { Input, Select, buttonClass } from '../../components';
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
  return <main className="mx-auto grid max-w-3xl gap-5 px-4 py-6 text-ink"><header className="flex items-center justify-between gap-5 [&_h1]:m-0 [&_h1]:font-display [&_h1]:text-[34px] [&_h1]:font-bold"><h1>{t('social.search.title')}</h1><Link className={buttonClass('secondary')} to={path('feed')}>{t('common.back')}</Link></header>
    <form className="grid gap-4 border border-(--hairline) bg-surface p-4 sm:grid-cols-[1fr_auto]" onSubmit={submit}><Input label={t('social.search.placeholder')} type="search" value={input} maxLength={200} onChange={(event) => setInput(event.currentTarget.value)} /><button className={`${buttonClass('primary')} self-end`} type="submit">{t('common.search')}</button><div className="sm:col-span-2"><Select label={t('social.search.filter')} value={filter} onChange={(event) => setFilter(event.currentTarget.value as typeof filter)}><option value="all">{t('social.search.all')}</option><option value="following">{t('social.search.following')}</option><option value="followers">{t('social.search.followers')}</option></Select></div></form>
    {results.isPending && query ? <div className="grid gap-3 [&>span]:h-14 [&>span]:animate-[shimmer_1000ms_linear_infinite_alternate] [&>span]:bg-surface-mid" aria-label={t('common.loading')}><span /><span /></div> : results.isError ? <section role="alert" className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center"><p>{t('common.error')}</p><button className={buttonClass('secondary')} onClick={() => void results.refetch()}>{t('common.retry')}</button></section> : query && !posts.length ? <section className="border border-(--hairline) bg-surface p-8 text-center">{t('social.empty.search')}</section> : posts.length ? <section className="grid gap-4">{posts.map((post) => <PostCard key={post.id} post={post} />)}</section> : null}
    {results.hasNextPage ? <button className={`${buttonClass('secondary')} justify-self-center`} disabled={results.isFetchingNextPage} onClick={() => void results.fetchNextPage()}>{t('social.loadMore')}</button> : null}
    {results.isFetchNextPageError ? <button className={buttonClass('secondary')} onClick={() => void results.fetchNextPage()}>{t('common.retry')}</button> : null}
  </main>;
}
export default function PostSearchRoute() { return <RequireAuth><SearchPage /></RequireAuth>; }
