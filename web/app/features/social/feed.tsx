import { useState, type FormEvent } from 'react';
import { Link } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { api } from '../../core/api';
import { useSession, RequireAuth } from '../../core/session';
import { ImageEditor } from '../../components/image-editor';
import { useI18n } from '../../core/locale';
import { userKey } from '../../core/query-client';
import { StoryRail } from '../stories';
import { useFeed, useSocialActions } from './queries';
import { PostCard } from './post-card';
import type { ContentFilter, FeedType, PostAudience, SocialUser } from './types';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };

function MentionPicker({ userId, selected, onChange }: { userId: string; selected: SocialUser[]; onChange: (users: SocialUser[]) => void }) {
  const { t } = useI18n(catalogs); const [search, setSearch] = useState(''); const term = search.trim();
  const people = useQuery({ queryKey: userKey(userId, 'social', 'mention-search', term), queryFn: ({ signal }) => api.get<{ users: SocialUser[] }>(`/users/search?q=${encodeURIComponent(term)}&limit=10&offset=0`, { signal }), enabled: term.length >= 2, gcTime: 0, staleTime: 0 });
  return <div className="grid min-w-44 flex-1 gap-2"><label className="ui-field">{t('social.create.mentionSearch')}<input value={search} onChange={(event) => setSearch(event.currentTarget.value)} placeholder={t('social.create.mentionSearchHint')} maxLength={100} /></label>{selected.length ? <ul className="flex flex-wrap gap-2">{selected.map((user) => <li key={user.id}><button className="ui-button ui-sm ui-secondary" type="button" onClick={() => onChange(selected.filter((item) => item.id !== user.id))}>{user.displayName} ×</button></li>)}</ul> : null}{people.isError ? <p role="alert" className="status status-error">{t('common.error')} <button className="underline" type="button" onClick={() => void people.refetch()}>{t('common.retry')}</button></p> : people.isPending && term.length >= 2 ? <p role="status">{t('common.loading')}</p> : people.data?.users.length ? <ul className="grid max-h-40 overflow-y-auto bg-surface-high p-1">{people.data.users.filter((user) => !selected.some((item) => item.id === user.id)).map((user) => <li key={user.id}><button type="button" className="w-full p-2 text-left hover:bg-surface-mid" onClick={() => { onChange([...selected, user]); setSearch(''); }}>{user.displayName}{user.username ? ` @${user.username}` : ''}</button></li>)}</ul> : term.length >= 2 && people.data ? <p className="text-xs text-muted">{t('social.create.mentionEmpty')}</p> : null}</div>;
}

function CreatePost({ userId }: { userId: string }) {
  const { t, path } = useI18n(catalogs); const actions = useSocialActions(userId);
  const [content, setContent] = useState(''); const [file, setFile] = useState<File>(); const [editingFile, setEditingFile] = useState<File>(); const [audience, setAudience] = useState<PostAudience>('EVERYONE'); const [mentions, setMentions] = useState<SocialUser[]>([]); const [error, setError] = useState('');
  async function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setError(''); if (file && (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type) || file.size > 5 * 1024 * 1024)) { setError(t('social.create.maxImage')); return; } try { await actions.createPost.mutateAsync({ content: content.trim(), type: 'REGULAR', audience, image: file, mentionIds: audience === 'EVERYONE' ? mentions.map((user) => user.id) : [] }); setContent(''); setFile(undefined); setMentions([]); const input = event.currentTarget.querySelector<HTMLInputElement>('input[type=file]'); if (input) input.value = ''; } catch { setError(t('social.create.error')); } }
  return <form className="surface grid gap-3" onSubmit={submit}>
    <label className="sr-only" htmlFor="social-post-content">{t('social.create.placeholder')}</label><textarea id="social-post-content" className="min-h-24 w-full resize-y bg-surface-mid p-3 text-ink" value={content} onChange={(event) => setContent(event.currentTarget.value)} maxLength={5000} placeholder={t('social.create.placeholder')} />
    <div className="flex flex-wrap items-end gap-3">
       <label className="ui-field min-w-36 flex-1">{t('social.create.audience')}<select value={audience} onChange={(event) => setAudience(event.currentTarget.value as PostAudience)}><option value="EVERYONE">{t('social.audience.everyone')}</option><option value="CLOSE_FRIENDS">{t('social.audience.closeFriends')}</option></select></label>
       {audience === 'CLOSE_FRIENDS' ? <Link className="text-sm font-bold text-brand" to={path('settings/close-friends')}>{t('social.audience.manage')}</Link> : null}
       <label className="ui-button ui-secondary ui-sm cursor-pointer">{t('social.create.image')}<input className="sr-only" type="file" accept="image/jpeg,image/png,image/webp,image/gif" onChange={(event) => { const selected = event.currentTarget.files?.[0]; if (selected) setEditingFile(selected); }} /></label>
      {audience === 'EVERYONE' ? <MentionPicker userId={userId} selected={mentions} onChange={setMentions} /> : null}
      <button className="ui-button ui-primary" disabled={actions.createPost.isPending || (!content.trim() && !file)}>{actions.createPost.isPending ? t('common.loading') : t('social.create.submit')}</button>
    </div>
     {file ? <p className="text-xs text-muted">{file.name}</p> : null}{error ? <p role="alert" className="status status-error">{error}</p> : null}
     {editingFile ? <div className="fixed inset-0 z-50 grid place-items-center overflow-y-auto bg-black/80 p-4" role="dialog" aria-modal="true"><ImageEditor file={editingFile} onSave={(edited) => { setFile(edited); setEditingFile(undefined); }} onCancel={() => setEditingFile(undefined)} /></div> : null}
  </form>;
}

function FeedPage() {
  const session = useSession(); const { t, path } = useI18n(catalogs); const userId = session.user?.id ?? '';
  const [type, setType] = useState<FeedType>('explore'); const [filter, setFilter] = useState<ContentFilter>('all');
  const feed = useFeed(userId, type, filter); const posts = feed.data?.pages.flatMap((page) => page.posts) ?? [];
  return <main className="mx-auto grid max-w-[1320px] gap-6 px-4 py-6 text-ink lg:grid-cols-[minmax(0,1fr)_300px] lg:px-8">
    <section className="grid min-w-0 content-start gap-5">
      <header className="page-header"><div><p className="eyebrow text-brand">{t('social.feed.eyebrow')}</p><h1>{t('social.feed.title')}</h1><p className="mt-1 text-muted">{t('social.feed.subtitle')}</p></div><Link className="ui-button ui-secondary hidden sm:inline-flex" to={path('search/posts')}>{t('common.search')}</Link></header>
      <div className="surface lg:hidden"><StoryRail /></div>
      <nav aria-label={t('social.feed.title')} className="flex flex-wrap gap-2"><button className={`ui-button ${type === 'explore' ? 'ui-primary' : 'ui-secondary'}`} aria-pressed={type === 'explore'} onClick={() => setType('explore')}>{t('social.feed.explore')}</button><button className={`ui-button ${type === 'following' ? 'ui-primary' : 'ui-secondary'}`} aria-pressed={type === 'following'} onClick={() => setType('following')}>{t('social.feed.following')}</button></nav>
      <nav aria-label={t('social.feed.typeFilter')} className="flex gap-2 overflow-x-auto">{(['all', 'social', 'selling'] as const).map((value) => <button key={value} className="ui-button ui-sm ui-ghost" aria-pressed={filter === value} onClick={() => setFilter(value)}>{t(`social.filter.${value}`)}</button>)}</nav>
      <CreatePost userId={userId} />
      {feed.isPending ? <div className="loading-list" aria-label={t('common.loading')}><span /><span /><span /></div> : feed.isError ? <section role="alert" className="error-state"><p>{t('common.error')}</p><button className="ui-button ui-secondary" onClick={() => void feed.refetch()}>{t('common.retry')}</button></section> : posts.length === 0 ? <section className="empty-state">{t('social.empty.feed')}</section> : <div className="grid gap-4">{posts.map((post) => <PostCard key={post.id} post={post} />)}</div>}
      {feed.hasNextPage ? <button className="ui-button ui-secondary justify-self-center" disabled={feed.isFetchingNextPage} onClick={() => void feed.fetchNextPage()}>{feed.isFetchingNextPage ? t('common.loading') : t('social.loadMore')}</button> : null}
      {feed.isFetchNextPageError ? <button className="ui-button ui-secondary justify-self-center" onClick={() => void feed.fetchNextPage()}>{t('common.retry')}</button> : null}
    </section>
     <aside className="hidden content-start gap-6 lg:grid"><div className="surface"><StoryRail /></div><section className="surface grid gap-3"><h2 className="font-display text-xl font-bold">{t('social.search.title')}</h2><Link className="ui-button ui-secondary" to={path('search/posts')}>{t('common.search')} ↗</Link><Link className="ui-button ui-ghost" to={path('saved')}>{t('social.saved.title')}</Link><Link className="ui-button ui-ghost" to={path('liked')}>{t('social.collection.liked')}</Link><Link className="ui-button ui-ghost" to={path('posts/mine')}>{t('social.collection.mine')}</Link></section></aside>
  </main>;
}

export default function FeedRoute() { return <RequireAuth><FeedPage /></RequireAuth>; }
