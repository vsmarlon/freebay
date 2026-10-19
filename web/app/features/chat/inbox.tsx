import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { RequireAuth, useSession } from '../../core/session';
import { useI18n } from '../../core/locale';
import { pathsFor } from '../../core/routes';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import { chatRepository } from './repository';
import { filterConversations, type Conversation, type CursorPage } from './model';
import { groupConversationsByCounterparty } from './inbox-grouping';

const catalogs = { en, 'pt-BR': ptBR };
function Inbox() {
  const { t, path } = useI18n(catalogs);
  const { user } = useSession();
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [archived, setArchived] = useState(false);
  const [page, setPage] = useState<CursorPage<Conversation> | null>(null);
  const [error, setError] = useState(false);
  const [pending, setPending] = useState(false);
  const [retry, setRetry] = useState(0);
  const [newQuery, setNewQuery] = useState('');
  const [newUsers, setNewUsers] = useState<Array<{ id: string; displayName: string; avatarUrl: string | null }>>([]);
  const [newUserOffset, setNewUserOffset] = useState<number | null>(null);
  const [newUserHasMore, setNewUserHasMore] = useState(false);
  const [blockedIds, setBlockedIds] = useState<Set<string>>(() => new Set());
  const [suggestedUsers, setSuggestedUsers] = useState<Array<{ id: string; displayName: string; avatarUrl: string | null }>>([]);
  const [followingUsers, setFollowingUsers] = useState<Array<{ id: string; displayName: string; avatarUrl: string | null }>>([]);
  const [threadType, setThreadType] = useState<'ALL' | 'DIRECT' | 'ORDER'>('ALL');
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [creating, setCreating] = useState(false);
  useEffect(() => {
    if (!creating || newQuery.trim().length < 2) { setNewUsers([]); setNewUserOffset(null); setNewUserHasMore(false); return; }
    const controller = new AbortController();
    const timer = window.setTimeout(() => { void chatRepository.searchUsers(newQuery.trim(), 0, controller.signal).then((result) => { setNewUsers(result.users); setNewUserOffset(result.nextOffset); setNewUserHasMore(result.hasMore); }).catch(() => { if (!controller.signal.aborted) setError(true); }); }, 180);
    return () => { window.clearTimeout(timer); controller.abort(); };
  }, [creating, newQuery]);
  useEffect(() => {
    if (!creating || !user?.id) return;
    const controller = new AbortController();
    void Promise.all([chatRepository.blockedUsers(controller.signal), chatRepository.suggestions(controller.signal), chatRepository.following(user.id, controller.signal)]).then(([blocked, suggestions, following]) => {
      if (controller.signal.aborted) return;
      setBlockedIds(new Set(blocked.users.map((person) => person.id)));
      setSuggestedUsers(suggestions.users);
      setFollowingUsers(following.users);
    }).catch(() => { if (!controller.signal.aborted) setError(true); });
    return () => controller.abort();
  }, [creating, user?.id]);
  async function loadMoreUsers() {
    if (newUserOffset === null) return;
    try { const result = await chatRepository.searchUsers(newQuery.trim(), newUserOffset); setNewUsers((users) => [...users, ...result.users]); setNewUserOffset(result.nextOffset); setNewUserHasMore(result.hasMore); }
    catch { setError(true); }
  }
  const visibleConversations = filterConversations(page?.items ?? [], threadType, unreadOnly);
  const conversationGroups = groupConversationsByCounterparty(visibleConversations);
  useEffect(() => {
    const controller = new AbortController();
    const timer = window.setTimeout(() => {
      setPending(true); setError(false);
      void chatRepository.conversations({ q: archived ? undefined : query, archived, signal: controller.signal }).then(setPage).catch(() => { if (!controller.signal.aborted) setError(true); }).finally(() => { if (!controller.signal.aborted) setPending(false); });
    }, 180);
    return () => { window.clearTimeout(timer); controller.abort(); };
  }, [query, archived, retry, user?.id]);

  useEffect(() => { setPage(null); setNewUsers([]); setError(false); }, [user?.id]);

  async function loadMore() {
    if (!page?.nextCursor || pending) return;
    setPending(true);
    try {
      const next = await chatRepository.conversations({ q: query, archived, cursor: page.nextCursor });
      setPage((old) => old ? { ...next, items: [...old.items, ...next.items] } : next);
    } catch { setError(true); }
    finally { setPending(false); }
  }
  return <main className="mx-auto min-h-screen max-w-6xl px-4 py-8 text-ink sm:px-8">
    <header className="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div><p className="text-xs font-bold uppercase tracking-widest text-brand">FREEBAY / CHAT</p><h1 className="font-display text-4xl font-bold">{t('chat.title')}</h1></div>
      <button className="ui-button ui-primary" type="button" onClick={() => setCreating((value) => !value)}>{t('chat.new')}</button>
      <button className="ui-button ui-secondary" type="button" aria-pressed={archived} onClick={() => { setArchived((value) => !value); setPage(null); }}>{archived ? t('chat.inbox') : t('chat.archived')}</button>
    </header>
    {creating ? <section className="surface mb-5 grid gap-2" aria-label={t('chat.new')}><label className="grid gap-2">{t('chat.searchPeople')}<input className="min-h-12 border-2 border-ink bg-surface-high px-3" type="search" value={newQuery} onChange={(event) => setNewQuery(event.currentTarget.value)} /></label>{(newQuery.trim().length >= 2 ? newUsers : [...followingUsers, ...suggestedUsers.filter((suggestion) => !followingUsers.some((follow) => follow.id === suggestion.id))]).filter((person) => !blockedIds.has(person.id)).map((person) => <button key={person.id} type="button" className="min-h-12 bg-surface-mid p-3 text-left" onClick={async () => { try { const result = await chatRepository.start(person.id); navigate(path(pathsFor.conversation(result.conversationId))); } catch { setError(true); } }}>{person.displayName}</button>)}{newQuery.trim().length >= 2 && newUserHasMore ? <button type="button" className="ui-button ui-secondary" onClick={() => void loadMoreUsers()}>{t('common.loadMore')}</button> : null}</section> : null}
    <nav className="mb-4 flex flex-wrap gap-2" aria-label={t('chat.title')}>
      {(['ALL', 'DIRECT', 'ORDER'] as const).map((kind) => <button key={kind} type="button" className="ui-button ui-secondary" aria-pressed={threadType === kind} onClick={() => setThreadType(kind)}>{t(`chat.filter.${kind}`)}</button>)}
      <button type="button" className="ui-button ui-secondary" aria-pressed={unreadOnly} onClick={() => setUnreadOnly((value) => !value)}>{t('chat.unreadFilter')}</button>
    </nav>
    {!archived ? <label className="mb-5 grid gap-2 text-sm font-semibold">{t('chat.search')}<input className="min-h-12 border-2 border-ink bg-surface-high px-3 text-ink" value={query} onChange={(event) => { setQuery(event.currentTarget.value); setPage(null); }} type="search" /></label> : null}
    {error ? <div className="surface" role="alert"><p>{t('chat.error')}</p><button className="ui-button ui-ghost" type="button" onClick={() => setRetry((value) => value + 1)}>{t('chat.retry')}</button></div> : null}
    {pending && !page ? <p role="status" className="surface">{t('common.loading')}</p> : null}
    {!pending && !error && visibleConversations.length === 0 ? <p className="surface" role="status">{t('chat.empty')}</p> : null}
    <div className="grid gap-4" aria-label={t('chat.title')}>
      {[...conversationGroups].map(([counterpartyId, conversations]) => <section key={counterpartyId} aria-label={conversations[0].otherUser.displayName}>
        <h2 className="mb-2 text-sm font-bold uppercase tracking-wide text-muted">{conversations[0].otherUser.displayName}</h2>
        <ul className="grid gap-2">
      {conversations.map((conversation) => <li key={`${conversation.threadType}:${conversation.id}`}>
        <Link to={path(pathsFor.conversation(conversation.id))} className="flex min-h-20 items-center gap-4 bg-surface p-4 hover:bg-surface-mid focus-visible:outline-2 focus-visible:outline-brand">
          {conversation.otherUser.avatarUrl ? <img className="avatar h-12 w-12 object-cover" src={conversation.otherUser.avatarUrl} alt="" /> : <span className="avatar grid h-12 w-12 place-items-center font-bold" aria-hidden="true">{conversation.otherUser.displayName.slice(0, 1)}</span>}
          <span className="min-w-0 flex-1"><span className="block truncate font-bold">{conversation.otherUser.displayName}</span><span className="block truncate text-sm text-muted">{conversation.product?.title ?? conversation.orderInfo?.productTitle ?? conversation.lastMessage?.content ?? t('chat.thread')}</span></span>
          <span className="text-right text-xs text-muted">{conversation.unreadCount > 0 ? t('chat.unread', { count: conversation.unreadCount }) : ''}</span>
        </Link>
      </li>)}
        </ul>
      </section>)}
    </div>
    {page?.nextCursor ? <button className="ui-button ui-secondary mt-4" disabled={pending} type="button" onClick={() => void loadMore()}>{t('common.loadMore')}</button> : null}
  </main>;
}
export default function ChatInboxPage() { return <RequireAuth><Inbox /></RequireAuth>; }
