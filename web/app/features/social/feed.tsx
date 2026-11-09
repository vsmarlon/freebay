import { useRef, useState, type FormEvent } from 'react';
import { Link } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { ComposerInput, Select, buttonClass } from '../../components';
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

const PaperclipIcon = () => (
  <svg
    width="16"
    height="16"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
  >
    <path d="M21.44 11.05 12.25 20.24a6 6 0 0 1-8.49-8.49l8.49-8.48a3.99 3.99 0 0 1 5.66 5.65l-8.49 8.49a1.5 1.5 0 0 1-2.12-2.12l7.78-7.78" />
  </svg>
);

function CreatePost({ userId }: { userId: string }) {
  const { t, path } = useI18n(catalogs);
  const actions = useSocialActions(userId);
  const [content, setContent] = useState('');
  const [file, setFile] = useState<File>();
  const [editingFile, setEditingFile] = useState<File>();
  const [audience, setAudience] = useState<PostAudience>('EVERYONE');
  const [mentions, setMentions] = useState<SocialUser[]>([]);
  const [error, setError] = useState('');
  // ponytail: inline @ mentions — @token under the caret queries people; no arrow-key nav, click or Enter picks first; upgrade if needed
  const [mention, setMention] = useState<{ start: number; term: string } | null>(null);
  const formRef = useRef<HTMLFormElement>(null);
  const term = mention?.term ?? '';
  const people = useQuery({
    queryKey: userKey(userId, 'social', 'mention-search', term),
    queryFn: ({ signal }) =>
      api.get<{ users: SocialUser[] }>(
        `/users/search?q=${encodeURIComponent(term)}&limit=10&offset=0`,
        { signal },
      ),
    enabled: audience === 'EVERYONE' && term.length >= 2,
    gcTime: 0,
    staleTime: 0,
  });
  const suggestions =
    audience === 'EVERYONE' && term.length >= 2
      ? (people.data?.users ?? [])
          .filter((user) => !mentions.some((item) => item.id === user.id))
          .slice(0, 5)
      : [];
  function syncMention(text: string, caret: number) {
    const match = /@([\w-]*)$/.exec(text.slice(0, caret));
    setMention(match ? { start: caret - match[0].length, term: match[1] } : null);
  }
  function pick(user: SocialUser) {
    if (mention) {
      const end = mention.start + 1 + mention.term.length;
      setContent(
        content.slice(0, mention.start) +
          (user.username ? `@${user.username} ` : `${user.displayName} `) +
          content.slice(end),
      );
    }
    setMentions((current) =>
      current.some((item) => item.id === user.id) ? current : [...current, user],
    );
    setMention(null);
  }
  async function doSubmit() {
    setError('');
    if (
      file &&
      (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type) ||
        file.size > 5 * 1024 * 1024)
    ) {
      setError(t('social.create.maxImage'));
      return;
    }
    try {
      await actions.createPost.mutateAsync({
        content: content.trim(),
        type: 'REGULAR',
        audience,
        image: file,
        mentionIds: audience === 'EVERYONE' ? mentions.map((user) => user.id) : [],
      });
      setContent('');
      setFile(undefined);
      setMentions([]);
      setMention(null);
      const input = formRef.current?.querySelector<HTMLInputElement>('input[type=file]');
      if (input) input.value = '';
    } catch {
      setError(t('social.create.error'));
    }
  }
  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void doSubmit();
  }
  // ponytail: Enter picks the highlighted-ish first mention instead of posting; no arrow-key nav
  function onEnterOverride() {
    if (suggestions.length) {
      pick(suggestions[0]);
      return true;
    }
    return false;
  }
  return (
    <form
      ref={formRef}
      className="border border-(--hairline) bg-surface p-4 grid gap-3"
      onSubmit={submit}
    >
      <ComposerInput
        id="social-post-content"
        label={t('social.create.placeholder')}
        placeholder={t('social.create.placeholder')}
        value={content}
        maxLength={5000}
        onChange={(value, caret) => {
          setContent(value);
          syncMention(value, caret ?? 0);
        }}
        onSubmit={doSubmit}
        onSubmitOverride={onEnterOverride}
        textareaProps={{
          role: 'combobox',
          'aria-expanded': suggestions.length > 0,
          'aria-controls': 'social-mention-list',
        }}
      />
      {term.length >= 2 && audience === 'EVERYONE' ? (
        <ul id="social-mention-list" className="grid max-h-40 overflow-y-auto bg-surface-high p-1">
          {people.isPending ? (
            <li role="status" className="p-2 text-xs text-muted">
              {t('common.loading')}
            </li>
          ) : suggestions.length ? (
            suggestions.map((user) => (
              <li key={user.id}>
                <button
                  type="button"
                  className="w-full p-2 text-left hover:bg-surface-mid"
                  onClick={() => pick(user)}
                >
                  {user.displayName}
                  {user.username ? ` @${user.username}` : ''}
                </button>
              </li>
            ))
          ) : (
            <li className="p-2 text-xs text-muted">{t('social.create.mentionEmpty')}</li>
          )}
        </ul>
      ) : null}
      <div className="flex flex-wrap items-end gap-3">
        <div className="min-w-36 flex-1">
          <Select
            label={t('social.create.audience')}
            value={audience}
            onChange={(event) => setAudience(event.currentTarget.value as PostAudience)}
          >
            <option value="EVERYONE">{t('social.audience.everyone')}</option>
            <option value="CLOSE_FRIENDS">{t('social.audience.closeFriends')}</option>
          </Select>
        </div>
        {audience === 'CLOSE_FRIENDS' ? (
          <Link className="text-sm font-bold text-brand" to={path('settings/close-friends')}>
            {t('social.audience.manage')}
          </Link>
        ) : null}
        <label
          className={`${buttonClass('secondary')} grid cursor-pointer place-items-center px-3`}
          title={t('social.create.image')}
          aria-label={t('social.create.image')}
        >
          <PaperclipIcon />
          <input
            className="sr-only"
            type="file"
            accept="image/jpeg,image/png,image/webp,image/gif"
            onChange={(event) => {
              const selected = event.currentTarget.files?.[0];
              if (selected) setEditingFile(selected);
            }}
          />
        </label>
        <button
          className={buttonClass('primary')}
          disabled={actions.createPost.isPending || (!content.trim() && !file)}
        >
          {actions.createPost.isPending ? t('common.loading') : t('social.create.submit')}
        </button>
      </div>
      {file ? <p className="text-xs text-muted">{file.name}</p> : null}
      {error ? (
        <p
          role="alert"
          className="inline-flex bg-surface-mid px-2 py-1 text-[11px] font-bold text-danger"
        >
          {error}
        </p>
      ) : null}
      {editingFile ? (
        <div
          className="fixed inset-0 z-50 grid place-items-center overflow-y-auto bg-black/80 p-4"
          role="dialog"
          aria-modal="true"
        >
          <ImageEditor
            file={editingFile}
            onSave={(edited) => {
              setFile(edited);
              setEditingFile(undefined);
            }}
            onCancel={() => setEditingFile(undefined)}
          />
        </div>
      ) : null}
    </form>
  );
}

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
