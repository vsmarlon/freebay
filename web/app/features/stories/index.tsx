import { Link } from 'react-router';
import { paths, pathsFor } from '../../core/routes';
import { RequireAuth, useSession } from '../../core/session';
import {
  Avatar,
  Media,
  useStories,
  useStoryCopy,
  type Feed,
  type Group,
  type Highlight,
  type Story,
} from './shared';

export function StoryRail({ userId }: { userId?: string }) {
  const { path, t } = useStoryCopy();
  const { user } = useSession();
  const ownerId = userId ?? user?.id;
  const endpoint = userId ? `/stories/user/${encodeURIComponent(userId)}` : '/stories';
  const { value, error, retry } = useStories<Feed | Story[]>(endpoint, userId ?? 'feed');
  const groups: Group[] = Array.isArray(value)
    ? value.length && value[0].user
      ? [{ user: value[0].user, stories: value }]
      : []
    : ((value as Feed | undefined)?.stories ?? []);
  const own = groups.find((group) => group.user.id === ownerId);
  return (
    <section aria-label={t.title} className="w-full text-ink">
      <div className="mb-3 flex items-center justify-between">
        <h2 className="font-display text-xl font-bold">{t.title}</h2>
        <Link className="text-sm font-bold text-brand" to={path(paths.storyArchive)}>
          {t.archive}
        </Link>
      </div>
      {error ? (
        <div role="alert">
          <p>{t.error}</p>
          <button className="text-brand" onClick={retry}>
            {t.retry}
          </button>
        </div>
      ) : !value ? (
        <p aria-live="polite">{t.loading}</p>
      ) : (
        <div className="flex gap-4 overflow-x-auto py-2">
          <Link
            to={path('stories/new')}
            aria-label={t.create}
            className="grid w-20 shrink-0 justify-items-center gap-2 text-xs"
          >
            <Avatar
              user={own?.user ?? { id: userId ?? '', displayName: t.create, avatarUrl: null }}
              className="w-16 ring-2 ring-brand"
            />
            <span>{t.create}</span>
          </Link>
          {own?.stories.length ? (
            <Link
              to={path(pathsFor.story(own.user.id))}
              className="grid w-20 shrink-0 justify-items-center gap-2 text-xs"
            >
              <Avatar user={own.user} className="w-16 ring-2 ring-success" />
              <span>{t.myStories}</span>
            </Link>
          ) : null}
          {groups
            .filter((group) => group.stories.length)
            .map((group) => (
              <Link
                key={group.user.id}
                to={path(pathsFor.story(group.user.id))}
                aria-label={`${group.user.displayName}, ${group.stories.length} stories`}
                className="grid w-20 shrink-0 justify-items-center gap-2 text-xs"
              >
                <Avatar user={group.user} className="w-16 ring-2 ring-brand" />
                <span className="max-w-20 truncate">{group.user.displayName}</span>
              </Link>
            ))}
          {!groups.length && <p className="text-ink-muted">{t.empty}</p>}
        </div>
      )}
    </section>
  );
}

export default function StoriesPage() {
  return (
    <RequireAuth>
      <StoryRail />
    </RequireAuth>
  );
}

export function ProfileHighlights({ userId }: { userId: string }) {
  const { path, t } = useStoryCopy();
  const { value, error, retry } = useStories<{ highlights: Highlight[] }>(
    `/stories/highlights/user/${encodeURIComponent(userId)}`,
    userId,
  );
  return (
    <section aria-label={t.highlights} className="space-y-3 text-ink">
      <h2 className="font-display text-xl font-bold">{t.highlights}</h2>
      {error ? (
        <button onClick={retry} role="alert">
          {t.retry}
        </button>
      ) : !value ? (
        <p aria-live="polite">{t.loading}</p>
      ) : value.highlights.length ? (
        <div className="flex gap-4 overflow-x-auto">
          {value.highlights.map((highlight) => (
            <Link
              key={highlight.id}
              to={path(`highlights/${encodeURIComponent(highlight.id)}`)}
              aria-label={highlight.title}
              className="grid w-20 shrink-0 justify-items-center gap-2 text-xs"
            >
              <span className="aspect-square w-16 overflow-hidden bg-surface-high">
                <Media
                  story={
                    {
                      ...(highlight.stories.find((story) => story.id === highlight.coverStoryId) ??
                        highlight.stories[0]),
                      imageUrl: highlight.coverUrl,
                    } as Story
                  }
                  enabled
                  autoPlay={false}
                  controls={false}
                  className="size-full object-cover"
                />
              </span>
              <span className="max-w-20 truncate">{highlight.title}</span>
            </Link>
          ))}
        </div>
      ) : (
        <p className="text-ink-muted">{t.noHighlights}</p>
      )}
    </section>
  );
}
