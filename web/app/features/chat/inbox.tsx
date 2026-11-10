import { useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { RequireAuth, useSession } from '../../core/session';
import { useI18n } from '../../core/locale';
import { pathsFor } from '../../core/routes';
import { useDebouncedValue } from '../../core/use-debounced-value';
import { Input } from '../../components';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import { chatRepository } from './repository';
import { filterConversations } from './model';
import { groupConversationsByCounterparty } from './inbox-grouping';
import { useInboxConversations, usePeopleSearch, useNewChatDirectory } from './queries';

const catalogs = { en, 'pt-BR': ptBR };
function Inbox() {
  const { t, path } = useI18n(catalogs);
  const { user } = useSession();
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [archived, setArchived] = useState(false);
  const [newQuery, setNewQuery] = useState('');
  const [creating, setCreating] = useState(false);
  const [threadType, setThreadType] = useState<'ALL' | 'DIRECT' | 'ORDER'>('ALL');
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [startFailed, setStartFailed] = useState(false);

  const debouncedQuery = useDebouncedValue(query, 180);
  const debouncedNewQuery = useDebouncedValue(newQuery, 180);
  const conversationsQuery = useInboxConversations(user?.id, debouncedQuery, archived);
  const items = conversationsQuery.data?.pages.flatMap((page) => page.items) ?? [];

  const searchActive = creating && newQuery.trim().length >= 2;
  const peopleQuery = usePeopleSearch(user?.id, debouncedNewQuery.trim(), searchActive);
  const directoryQuery = useNewChatDirectory(user?.id, creating);

  const visibleConversations = filterConversations(items, threadType, unreadOnly);
  const conversationGroups = groupConversationsByCounterparty(visibleConversations);
  const people = searchActive
    ? (peopleQuery.data?.pages.flatMap((page) => page.users) ?? [])
    : [
        ...(directoryQuery.data?.following ?? []),
        ...(directoryQuery.data?.suggestions ?? []).filter(
          (suggestion) =>
            !(directoryQuery.data?.following ?? []).some((follow) => follow.id === suggestion.id),
        ),
      ];
  const blockedIds = directoryQuery.data?.blocked ?? new Set<string>();

  const error =
    conversationsQuery.isError ||
    conversationsQuery.isFetchNextPageError ||
    (creating && Boolean(user?.id) && directoryQuery.isError) ||
    (searchActive && peopleQuery.isError) ||
    startFailed;
  async function loadMore() {
    try {
      await conversationsQuery.fetchNextPage();
    } catch {
      /* surfaced through isFetchNextPageError below */
    }
  }
  async function loadMorePeople() {
    try {
      await peopleQuery.fetchNextPage();
    } catch {
      /* search rows stay; each retries */
    }
  }
  async function startConversation(personId: string) {
    setStartFailed(false);
    try {
      const result = await chatRepository.start(personId);
      navigate(path(pathsFor.conversation(result.conversationId)));
    } catch {
      setStartFailed(true);
    }
  }
  function retryAll() {
    setStartFailed(false);
    void conversationsQuery.refetch();
    if (creating) {
      void directoryQuery.refetch();
      if (searchActive) void peopleQuery.refetch();
    }
  }
  return (
    <main className="mx-auto min-h-screen max-w-6xl px-4 py-8 text-ink sm:px-8">
      <header className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-brand">FREEBAY / CHAT</p>
          <h1 className="font-display text-4xl font-bold">{t('chat.title')}</h1>
        </div>
        <button
          className="ui-button ui-primary"
          type="button"
          onClick={() => setCreating((value) => !value)}
        >
          {t('chat.new')}
        </button>
        <button
          className="ui-button ui-secondary"
          type="button"
          aria-pressed={archived}
          onClick={() => setArchived((value) => !value)}
        >
          {archived ? t('chat.inbox') : t('chat.archived')}
        </button>
      </header>
      {creating ? (
        <section className="surface mb-5 grid gap-2" aria-label={t('chat.new')}>
          <Input
            label={t('chat.searchPeople')}
            placeholder={t('chat.searchPeople')}
            type="search"
            value={newQuery}
            onChange={(event) => setNewQuery(event.currentTarget.value)}
          />
          {people
            .filter((person) => !blockedIds.has(person.id))
            .map((person) => (
              <button
                key={person.id}
                type="button"
                className="min-h-12 bg-surface-mid p-3 text-left"
                onClick={() => void startConversation(person.id)}
              >
                {person.displayName}
              </button>
            ))}
          {searchActive && peopleQuery.hasNextPage ? (
            <button
              type="button"
              className="ui-button ui-secondary"
              disabled={peopleQuery.isFetchingNextPage}
              onClick={() => void loadMorePeople()}
            >
              {t('common.loadMore')}
            </button>
          ) : null}
        </section>
      ) : null}
      <nav className="mb-4 flex flex-wrap gap-2" aria-label={t('chat.title')}>
        {(['ALL', 'DIRECT', 'ORDER'] as const).map((kind) => (
          <button
            key={kind}
            type="button"
            className="ui-button ui-secondary"
            aria-pressed={threadType === kind}
            onClick={() => setThreadType(kind)}
          >
            {t(`chat.filter.${kind}`)}
          </button>
        ))}
        <button
          type="button"
          className="ui-button ui-secondary"
          aria-pressed={unreadOnly}
          onClick={() => setUnreadOnly((value) => !value)}
        >
          {t('chat.unreadFilter')}
        </button>
      </nav>
      {!archived ? (
        <label className="mb-5 grid gap-2 text-sm font-semibold">
          {t('chat.search')}
          <input
            className="min-h-12 border-2 border-ink bg-surface-high px-3 text-ink"
            value={query}
            placeholder={t('chat.search')}
            onChange={(event) => setQuery(event.currentTarget.value)}
            type="search"
          />
        </label>
      ) : null}
      {error ? (
        <div className="surface" role="alert">
          <p>{t('chat.error')}</p>
          <button className="ui-button ui-ghost" type="button" onClick={retryAll}>
            {t('chat.retry')}
          </button>
        </div>
      ) : null}
      {conversationsQuery.isPending ? (
        <p role="status" className="surface">
          {t('common.loading')}
        </p>
      ) : null}
      {!error && !conversationsQuery.isPending && visibleConversations.length === 0 ? (
        <p className="surface" role="status">
          {t('chat.empty')}
        </p>
      ) : null}
      <div className="grid gap-4" aria-label={t('chat.title')}>
        {[...conversationGroups].map(([counterpartyId, conversations]) => (
          <section key={counterpartyId} aria-label={conversations[0].otherUser.displayName}>
            <h2 className="mb-2 text-sm font-bold uppercase tracking-wide text-muted">
              {conversations[0].otherUser.displayName}
            </h2>
            <ul className="grid gap-2">
              {conversations.map((conversation) => (
                <li key={`${conversation.threadType}:${conversation.id}`}>
                  <Link
                    to={path(pathsFor.conversation(conversation.id))}
                    className="flex min-h-20 items-center gap-4 bg-surface p-4 border border-(--hairline) hover:bg-surface-mid focus-visible:outline-2 focus-visible:outline-brand"
                  >
                    {conversation.otherUser.avatarUrl ? (
                      <img
                        className="avatar size-12 object-cover"
                        src={conversation.otherUser.avatarUrl}
                        alt=""
                      />
                    ) : (
                      <span
                        className="avatar grid size-12 place-items-center font-bold"
                        aria-hidden="true"
                      >
                        {conversation.otherUser.displayName.slice(0, 1)}
                      </span>
                    )}
                    <span className="min-w-0 flex-1">
                      <span className="block truncate font-bold">
                        {conversation.otherUser.displayName}
                      </span>
                      <span className="block truncate text-sm text-muted">
                        {conversation.product?.title ??
                          conversation.orderInfo?.productTitle ??
                          conversation.lastMessage?.content ??
                          t('chat.thread')}
                      </span>
                    </span>
                    <span className="text-right text-xs text-muted">
                      {conversation.unreadCount > 0
                        ? t('chat.unread', { count: conversation.unreadCount })
                        : ''}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ))}
      </div>
      {conversationsQuery.hasNextPage ? (
        <button
          className="ui-button ui-secondary mt-4"
          disabled={conversationsQuery.isFetchingNextPage}
          type="button"
          onClick={() => void loadMore()}
        >
          {t('common.loadMore')}
        </button>
      ) : null}
    </main>
  );
}
export default function ChatInboxPage() {
  return (
    <RequireAuth>
      <Inbox />
    </RequireAuth>
  );
}
