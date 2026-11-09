import { useEffect, useState } from 'react';
import { api } from '../../core/api';
import { RequireAuth } from '../../core/session';
import { Button, Dialog } from '../../components';
import { Media, useStories, useStoryCopy, type Highlight, type Story } from './shared';

export function StoryArchive() {
  const { locale, t } = useStoryCopy();
  const { value, error, retry } = useStories<{ stories: Story[] }>('/stories/archive', 'archive');
  const [selected, setSelected] = useState<string[]>([]);
  const [title, setTitle] = useState('');
  const [cover, setCover] = useState('');
  const [editing, setEditing] = useState<string>();
  const [highlights, setHighlights] = useState<Highlight[]>([]);
  const [mutationError, setMutationError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState<{
    kind: 'story' | 'highlight';
    id: string;
  } | null>(null);
  const ownerId = value?.stories[0]?.user?.id;

  // Highlights of the archive owner, refetched whenever the archive page lands
  // at a different owner; async writes only, the empty case derives instead of
  // an explicit reset.
  useEffect(() => {
    if (!ownerId) return;
    const controller = new AbortController();
    void api
      .get<{ highlights: Highlight[] }>(`/stories/highlights/user/${encodeURIComponent(ownerId)}`, {
        signal: controller.signal,
      })
      .then((response) => setHighlights(response.highlights))
      .catch(() => {
        if (!controller.signal.aborted) setMutationError(t.error);
      });
    return () => controller.abort();
  }, [ownerId, t.error]);
  const shownHighlights = ownerId ? highlights : [];

  async function save(event: React.FormEvent) {
    event.preventDefault();
    try {
      const body = { title, storyIds: selected, coverStoryId: cover };
      if (editing) await api.patch(`/stories/highlights/${encodeURIComponent(editing)}`, body);
      else await api.post('/stories/highlights', body);
      setSelected([]);
      setTitle('');
      setCover('');
      setEditing(undefined);
      retry();
    } catch {
      setMutationError(t.error);
    }
  }
  async function remove(id: string) {
    try {
      await api.patch(`/stories/${encodeURIComponent(id)}/delete`);
      retry();
    } catch {
      setMutationError(t.error);
    }
  }
  async function removeHighlight(id: string) {
    try {
      await api.patch(`/stories/highlights/${encodeURIComponent(id)}/delete`);
      setHighlights((items) => items.filter((item) => item.id !== id));
    } catch {
      setMutationError(t.error);
    }
  }
  function editHighlight(highlight: Highlight) {
    setEditing(highlight.id);
    setTitle(highlight.title);
    setSelected(highlight.stories.map((story) => story.id));
    setCover(highlight.coverStoryId);
  }

  return (
    <div className="mx-auto min-h-screen max-w-4xl space-y-6 p-6 text-ink">
      <h1 className="font-display text-3xl font-bold">{t.archive}</h1>
      {error ? (
        <button role="alert" onClick={retry}>
          {t.retry}
        </button>
      ) : !value ? (
        <p aria-live="polite">{t.loading}</p>
      ) : (
        <>
          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="font-display text-xl font-bold">{t.highlights}</h2>
              <button
                onClick={() => {
                  setEditing(undefined);
                  setTitle('');
                  setSelected([]);
                  setCover('');
                }}
              >
                {t.newHighlight}
              </button>
            </div>
            {shownHighlights.map((highlight) => (
              <article
                key={highlight.id}
                className="flex items-center justify-between bg-surface p-3"
              >
                <span>{highlight.title}</span>
                <span className="flex gap-3">
                  <button onClick={() => editHighlight(highlight)}>{t.edit}</button>
                  <button onClick={() => setDeleteTarget({ kind: 'highlight', id: highlight.id })}>
                    {t.delete}
                  </button>
                </span>
              </article>
            ))}
          </section>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {value.stories.map((story) => (
              <article key={story.id} className="bg-surface p-2">
                <button
                  className="block w-full text-left"
                  onClick={() => {
                    if (selected.includes(story.id)) {
                      const next = selected.filter((id) => id !== story.id);
                      setSelected(next);
                      if (cover === story.id) setCover(next[0] ?? '');
                    } else {
                      setSelected([...selected, story.id]);
                      if (!cover) setCover(story.id);
                    }
                  }}
                  aria-pressed={selected.includes(story.id)}
                >
                  <span className="block aspect-3/4 overflow-hidden bg-surface-mid">
                    <Media story={story} enabled className="size-full object-cover" />
                  </span>
                  <span>
                    {selected.includes(story.id) ? '✓ ' : ''}
                    {new Date(story.createdAt).toLocaleDateString(locale)}
                  </span>
                  {story.viewsCount !== undefined && (
                    <span className="block">
                      {t.views}: {story.viewsCount}
                    </span>
                  )}
                </button>
                <button
                  onClick={() => setDeleteTarget({ kind: 'story', id: story.id })}
                  className="mt-2 text-sm text-brand"
                >
                  {t.deleteStory}
                </button>
              </article>
            ))}
          </div>
          <form className="space-y-3 bg-surface p-4" onSubmit={save}>
            <label className="block">
              {t.titleField}
              <input
                maxLength={40}
                required
                value={title}
                onChange={(event) => setTitle(event.target.value)}
                className="ml-3 bg-surface-mid p-2"
              />
            </label>
            <fieldset>
              <legend>{t.cover}</legend>
              {value.stories
                .filter((story) => selected.includes(story.id))
                .map((story) => (
                  <label key={story.id} className="mr-4">
                    <input
                      type="radio"
                      name="cover"
                      value={story.id}
                      checked={cover === story.id}
                      onChange={() => setCover(story.id)}
                    />{' '}
                    {new Date(story.createdAt).toLocaleDateString(locale)}
                  </label>
                ))}
            </fieldset>
            <p>{t.chooseStories}</p>
            {mutationError && <p role="alert">{mutationError}</p>}
            <button disabled={!selected.length || !cover} className="bg-brand px-4 py-3 text-white">
              {editing ? t.edit : t.save}
            </button>
          </form>
          <Dialog
            open={deleteTarget !== null}
            onClose={() => setDeleteTarget(null)}
            title={deleteTarget?.kind === 'story' ? t.deleteStory : t.delete}
            actions={
              <>
                <Button variant="secondary" onClick={() => setDeleteTarget(null)}>
                  {t.cancel}
                </Button>
                <Button
                  variant="danger"
                  onClick={() => {
                    const target = deleteTarget;
                    setDeleteTarget(null);
                    if (target)
                      void (target.kind === 'story'
                        ? remove(target.id)
                        : removeHighlight(target.id));
                  }}
                >
                  {t.delete}
                </Button>
              </>
            }
          >
            {t.confirmDelete}
          </Dialog>
        </>
      )}
    </div>
  );
}

export function StoryArchiveRoute() {
  return (
    <RequireAuth>
      <StoryArchive />
    </RequireAuth>
  );
}

export default StoryArchiveRoute;
