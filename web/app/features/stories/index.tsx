import { useCallback, useRef, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { api } from '../../core/api';
import { useI18n } from '../../core/locale';
import { paths, pathsFor } from '../../core/routes';
import { useMediaUrl } from '../../core/media';
import { RequireAuth, useSession } from '../../core/session';
import { ImageEditor } from '../../components/image-editor';
import { Button, Dialog } from '../../components';
import { isCurrentStoryReady, shouldAutoAdvanceStory, storyAdvanceDelayMs } from './story-timing';
import { serializeStoryTextBlocks, StoryTextBlockEditor, StoryTextOverlays, type StoryTextBlock } from './text-block-editor';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import './stories.css';

type User = { id: string; displayName: string; avatarUrl: string | null; isVerified?: boolean };
type Story = { id: string; userId?: string; imageUrl: string; mediaType: 'IMAGE' | 'VIDEO'; audience: 'EVERYONE' | 'CLOSE_FRIENDS'; caption: string | null; textBlocks: StoryTextBlock[]; createdAt: string; expiresAt: string; viewsCount?: number; user?: User };
type Group = { user: User; stories: Story[] };
type Highlight = { id: string; title: string; user: User; coverStoryId: string; coverUrl: string; stories: Story[] };
type Feed = { stories: Group[]; userHasStory: boolean };

const copy = { en, 'pt-BR': ptBR };
const privateMediaPath = (src: string) => { if (src.startsWith('/media/story/')) return src; const name = src.split('/').pop(); return name ? `/media/story/${encodeURIComponent(name)}` : ''; };

function Media({ story, enabled, paused = false, autoPlay, controls, className = '', onReady, onError, onEnded, onPlaybackState }: { story: Story; enabled: boolean; paused?: boolean; autoPlay?: boolean; controls?: boolean; className?: string; onReady?: (durationMs?: number) => void; onError?: () => void; onEnded?: () => void; onPlaybackState?: (playing: boolean) => void }) {
  const { user } = useSession();
  const play = autoPlay ?? Boolean(onEnded); const showControls = controls ?? Boolean(onEnded);
  return <PrivateStoryMedia key={`${story.id}:${user?.id ?? ''}`} story={story} enabled={enabled && Boolean(user)} paused={paused} autoPlay={play} controls={showControls} className={className} onReady={onReady} onError={onError} onEnded={onEnded} onPlaybackState={onPlaybackState} />;
}

function PrivateStoryMedia({ story, enabled, paused, autoPlay, controls, className, onReady, onError, onEnded, onPlaybackState }: { story: Story; enabled: boolean; paused: boolean; autoPlay: boolean; controls: boolean; className: string; onReady?: (durationMs?: number) => void; onError?: () => void; onEnded?: () => void; onPlaybackState?: (playing: boolean) => void }) {
  const { locale } = useI18n(copy); const { url, isPending, error } = useMediaUrl(privateMediaPath(story.imageUrl), enabled);
  const videoRef = useCallback((video: HTMLVideoElement | null) => { if (!video || !autoPlay) return; if (paused) video.pause(); else void video.play().catch(() => {}); }, [paused, url, autoPlay]);
  if (error) return <div role="alert" className="grid h-full place-items-center bg-surface-mid p-6 text-center text-ink-muted">{locale === 'en' ? copy.en.permission : copy['pt-BR'].permission}</div>;
  if (!url) return <div aria-label={locale === 'en' ? copy.en.loading : copy['pt-BR'].loading} className={`h-full bg-surface-mid ${isPending ? 'animate-pulse' : ''}`} />;
  return story.mediaType === 'VIDEO' ? <video ref={videoRef} className={className} src={url} controls={controls} playsInline autoPlay={autoPlay} preload={autoPlay ? 'auto' : 'metadata'} onLoadedData={(event) => onReady?.(event.currentTarget.duration * 1000)} onPlay={() => onPlaybackState?.(true)} onPause={() => onPlaybackState?.(false)} onEnded={onEnded} onError={onError} /> : <img className={className} src={url} alt={story.caption ?? ''} onLoad={() => onReady?.()} onError={onError} />;
}

function useStories<T>(path: string, key: string) {
  const { user } = useSession();
  const query = useQuery<T>({ queryKey: ['stories', path, key, user?.id], queryFn: ({ signal }) => api.get<T>(path, { signal }), retry: false });
  return { value: query.data, error: query.isError, retry: () => void query.refetch() };
}

function Avatar({ user, className = '' }: { user: User; className?: string }) {
  return <span className={`grid aspect-square shrink-0 place-items-center overflow-hidden bg-surface-high text-ink ${className}`} aria-label={user.displayName}>{user.avatarUrl ? <img className="h-full w-full object-cover" src={user.avatarUrl} alt="" /> : user.displayName.slice(0, 1).toUpperCase()}</span>;
}

export function StoryRail({ userId }: { userId?: string }) {
  const { locale, path } = useI18n(copy); const { user } = useSession(); const ownerId = userId ?? user?.id; const endpoint = userId ? `/stories/user/${encodeURIComponent(userId)}` : '/stories';
  const { value, error, retry } = useStories<Feed | Story[]>(endpoint, userId ?? 'feed');
  const groups: Group[] = Array.isArray(value) ? value.length && value[0].user ? [{ user: value[0].user, stories: value }] : [] : (value as Feed | undefined)?.stories ?? [];
  const own = groups.find((group) => group.user.id === ownerId);
  return <section aria-label={locale === 'en' ? copy.en.title : copy['pt-BR'].title} className="w-full text-ink">
    <div className="mb-3 flex items-center justify-between"><h2 className="font-display text-xl font-bold">{locale === 'en' ? copy.en.title : copy['pt-BR'].title}</h2><Link className="text-sm font-bold text-brand" to={path(paths.storyArchive)}>{locale === 'en' ? copy.en.archive : copy['pt-BR'].archive}</Link></div>
    {error ? <div role="alert"><p>{locale === 'en' ? copy.en.error : copy['pt-BR'].error}</p><button className="text-brand" onClick={retry}>{locale === 'en' ? copy.en.retry : copy['pt-BR'].retry}</button></div> : !value ? <p aria-live="polite">{locale === 'en' ? copy.en.loading : copy['pt-BR'].loading}</p> : <div className="flex gap-4 overflow-x-auto py-2">
       <Link to={path('stories/new')} aria-label={locale === 'en' ? copy.en.create : copy['pt-BR'].create} className="grid w-20 shrink-0 justify-items-center gap-2 text-xs"><Avatar user={own?.user ?? { id: userId ?? '', displayName: locale === 'en' ? 'Add story' : 'Adicionar story', avatarUrl: null }} className="w-16 ring-2 ring-brand" /><span>{locale === 'en' ? copy.en.create : copy['pt-BR'].create}</span></Link>
       {own?.stories.length ? <Link to={path(pathsFor.story(own.user.id))} className="grid w-20 shrink-0 justify-items-center gap-2 text-xs"><Avatar user={own.user} className="w-16 ring-2 ring-success" /><span>{locale === 'en' ? copy.en.myStories : copy['pt-BR'].myStories}</span></Link> : null}
      {groups.filter((group) => group.stories.length).map((group) => <Link key={group.user.id} to={path(pathsFor.story(group.user.id))} aria-label={`${group.user.displayName}, ${group.stories.length} ${locale === 'en' ? 'stories' : 'stories'}`} className="grid w-20 shrink-0 justify-items-center gap-2 text-xs"><Avatar user={group.user} className="w-16 ring-2 ring-brand" /><span className="max-w-20 truncate">{group.user.displayName}</span></Link>)}
      {!groups.length && <p className="text-ink-muted">{locale === 'en' ? copy.en.empty : copy['pt-BR'].empty}</p>}
    </div>}
  </section>;
}

export default function StoriesPage() { return <RequireAuth><StoryRail /></RequireAuth>; }

export function ProfileHighlights({ userId }: { userId: string }) {
  const { locale, path } = useI18n(copy); const { value, error, retry } = useStories<{ highlights: Highlight[] }>(`/stories/highlights/user/${encodeURIComponent(userId)}`, userId);
  return <section aria-label={locale === 'en' ? copy.en.highlights : copy['pt-BR'].highlights} className="space-y-3 text-ink"><h2 className="font-display text-xl font-bold">{locale === 'en' ? copy.en.highlights : copy['pt-BR'].highlights}</h2>{error ? <button onClick={retry} role="alert">{locale === 'en' ? copy.en.retry : copy['pt-BR'].retry}</button> : !value ? <p aria-live="polite">{locale === 'en' ? copy.en.loading : copy['pt-BR'].loading}</p> : value.highlights.length ? <div className="flex gap-4 overflow-x-auto">{value.highlights.map((highlight) => <Link key={highlight.id} to={path(`highlights/${encodeURIComponent(highlight.id)}`)} aria-label={highlight.title} className="grid w-20 shrink-0 justify-items-center gap-2 text-xs"><span className="aspect-square w-16 overflow-hidden bg-surface-high"><Media story={{ ...highlight.stories.find((story) => story.id === highlight.coverStoryId) ?? highlight.stories[0], imageUrl: highlight.coverUrl } as Story} enabled autoPlay={false} controls={false} className="h-full w-full object-cover" /></span><span className="max-w-20 truncate">{highlight.title}</span></Link>)}</div> : <p className="text-ink-muted">{locale === 'en' ? copy.en.noHighlights : copy['pt-BR'].noHighlights}</p>}</section>;
}

export function StoryViewer() {
  const { userId = '' } = useParams(); const navigate = useNavigate(); const { locale } = useI18n(copy); const t = locale === 'en' ? copy.en : copy['pt-BR'];
  const { value, error, retry } = useStories<Story[]>(`/stories/user/${encodeURIComponent(userId)}`, userId); const stories = value ?? [];
  const [index, setIndex] = useState(0); const [readyMedia, setReadyMedia] = useState<{ storyId: string; durationMs?: number }>(); const [failedMediaId, setFailedMediaId] = useState<string>(); const [paused, setPaused] = useState(false); const [prevStoryId, setPrevStoryId] = useState<string | undefined>(); const viewed = useRef(new Set<string>()); const current = stories[index];
  const ready = isCurrentStoryReady(current?.id, readyMedia?.storyId) && failedMediaId !== current?.id;
  if (current?.id !== prevStoryId) { setPaused(false); setPrevStoryId(current?.id); }
  const move = useCallback((next: number) => { if (next < 0 || next >= stories.length) navigate(-1); else setIndex(next); }, [navigate, stories.length]);
  const storyViewerRef = useCallback((node: HTMLElement | null) => {
    if (!node || !current) return;
    // the ref callback re-runs on pause/index changes; post the view once per story
    if (ready && !viewed.current.has(current.id)) { viewed.current.add(current.id); void api.post(`/stories/${encodeURIComponent(current.id)}/view`).catch(() => {}); }
    if (current.mediaType !== 'VIDEO' && shouldAutoAdvanceStory(ready, paused)) {
      // the last slide closes the viewer, matching the video path's onEnded
      const timer = window.setTimeout(() => move(index + 1), storyAdvanceDelayMs('IMAGE'));
      const onKey = (event: KeyboardEvent) => { if (event.key === 'ArrowLeft') move(index - 1); if (event.key === 'ArrowRight') move(index + 1); if (event.key === 'Escape') navigate(-1); };
      window.addEventListener('keydown', onKey);
      return () => { window.clearTimeout(timer); window.removeEventListener('keydown', onKey); };
    }
    const onKey = (event: KeyboardEvent) => { if (event.key === 'ArrowLeft') move(index - 1); if (event.key === 'ArrowRight') move(index + 1); if (event.key === 'Escape') navigate(-1); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [current?.id, current?.mediaType, ready, paused, index, move, navigate]);
  return <div ref={storyViewerRef} className="min-h-screen bg-canvas text-ink"><div className="mx-auto grid min-h-screen max-w-5xl place-items-center p-4"><section className="relative h-[min(82vh,760px)] w-full max-w-md overflow-hidden bg-surface" onPointerDown={current?.mediaType === 'IMAGE' ? () => setPaused(true) : undefined} onPointerUp={current?.mediaType === 'IMAGE' ? () => setPaused(false) : undefined} onPointerCancel={current?.mediaType === 'IMAGE' ? () => setPaused(false) : undefined} onKeyDown={(event) => { if (event.key === ' ') { event.preventDefault(); setPaused((state) => !state); } }} tabIndex={0} aria-label={current ? t.progress.replace('{position}', String(index + 1)).replace('{total}', String(stories.length)) : t.title}>
    {error ? <div className="grid h-full place-items-center"><div role="alert" className="space-y-4 text-center"><p>{t.error}</p><button onClick={retry}>{t.retry}</button></div></div> : !current ? <p className="p-8" aria-live="polite">{value ? t.unavailable : t.loading}</p> : <><Media key={current.id} story={current} enabled paused={paused} className="absolute inset-0 h-full w-full object-contain" onReady={(durationMs) => setReadyMedia({ storyId: current.id, durationMs })} onPlaybackState={(playing) => setPaused(!playing)} onEnded={() => move(index + 1)} onError={() => setFailedMediaId(current.id)} /> <div className="absolute inset-x-3 top-3 z-10 flex gap-1" aria-hidden="true">{stories.map((story, position) => <span key={story.id} className="h-1 flex-1 bg-surface-high"><span className={`story-progress block h-full bg-ink ${position < index ? 'scale-x-100' : position === index && ready ? `is-running ${paused ? 'is-paused' : ''}` : ''}`} style={{ animationDuration: `${storyAdvanceDelayMs(current.mediaType, readyMedia?.storyId === current.id ? readyMedia.durationMs : undefined)}ms` }} /></span>)}</div><div className="absolute inset-x-3 top-7 z-10 flex items-center justify-between"><span className="font-bold text-white">{current.user?.displayName}{current.viewsCount !== undefined ? ` · ${current.viewsCount} ${t.views}` : ''}</span><button className="bg-surface-high px-3 py-2 text-ink" onClick={() => navigate(-1)} aria-label={t.closeViewer}>×</button></div>
      <button aria-label={t.previous} className="absolute inset-y-16 left-0 z-10 w-1/4" onClick={() => move(index - 1)} /><button aria-label={t.next} className="absolute inset-y-16 right-0 z-10 w-1/4" onClick={() => move(index + 1)} />
      {failedMediaId === current.id ? <p role="alert" className="absolute inset-x-4 top-16 z-20 bg-surface-high p-3">{t.mediaError}</p> : null}{current.caption && <p className="absolute inset-x-4 bottom-5 z-10 text-center text-white [text-shadow:0_1px_3px_#000]">{current.caption}</p>}<StoryTextOverlays blocks={current.textBlocks ?? []} />
      {!ready && <span className="sr-only" aria-live="polite">{t.loading}</span>}{paused && <span className="absolute bottom-16 left-1/2 z-10 -translate-x-1/2 bg-surface-high px-3 py-2">{t.paused}</span>}
    </>}
  </section></div></div>;
}

export function CreateStory() {
  const { locale, path } = useI18n(copy); const t = locale === 'en' ? copy.en : copy['pt-BR']; const navigate = useNavigate(); const [file, setFile] = useState<File>(); const [editingFile, setEditingFile] = useState<File>(); const [caption, setCaption] = useState(''); const [audience, setAudience] = useState<'EVERYONE' | 'CLOSE_FRIENDS'>('EVERYONE'); const [blocks, setBlocks] = useState<StoryTextBlock[]>([]); const [pending, setPending] = useState(false); const [error, setError] = useState('');
  const submit = async (event: React.FormEvent) => { event.preventDefault(); if (!file) { setError(t.fileRequired); return; } const video = file.type.startsWith('video/'); const allowed = video ? ['video/mp4', 'video/quicktime', 'video/webm'] : ['image/jpeg', 'image/png', 'image/webp', 'image/gif']; if (!allowed.includes(file.type)) { setError(t.unsupported); return; } if (file.size > (video ? 25 : 5) * 1024 * 1024 || caption.length > 500 || blocks.length > 10 || blocks.some((block) => !block.text.trim() || block.text.length > 200)) { setError(t.submitError); return; } const form = new FormData(); form.append('image', file); form.append('audience', audience); form.append('caption', caption); form.append('textBlocks', serializeStoryTextBlocks(blocks)); setPending(true); setError(''); try { await api.post('/stories', form); navigate(path(paths.feed), { replace: true }); } catch { setError(t.submitError); } finally { setPending(false); } };
  return <div className="mx-auto min-h-screen max-w-xl bg-canvas p-6 text-ink"><Link to={path(paths.feed)}>{t.cancel}</Link><h1 className="my-6 font-display text-3xl font-bold">{t.create}</h1><form className="space-y-5" onSubmit={(event) => void submit(event)}><label className="block space-y-2"><span>{t.file}</span><input required type="file" accept="image/jpeg,image/png,image/webp,image/gif,video/mp4,video/quicktime,video/webm" capture="environment" onChange={(event) => { const selected = event.currentTarget.files?.[0]; if (selected?.type.startsWith('video/')) setFile(selected); else if (selected) setEditingFile(selected); }} /></label><p className="text-sm text-ink-muted">{t.uploadLimit}</p>{file ? <StoryTextBlockEditor file={file} blocks={blocks} onChange={setBlocks} copy={{ addText: t.addText, removeText: t.removeText, text: t.text, style: t.textStyle, color: t.textColor, positionX: t.positionX, positionY: t.positionY, size: t.textSize, rotation: t.textRotation, layer: t.textLayer, videoPreview: t.videoPreview, defaultText: t.defaultText, colors: t.colors.split('|') }} /> : null}<label className="ui-field"><span>{t.caption}</span><textarea maxLength={500} value={caption} onChange={(event) => setCaption(event.target.value)} className="min-h-24" /></label><label className="ui-field"><span>{t.audience}</span><select value={audience} onChange={(event) => setAudience(event.target.value as typeof audience)}><option value="EVERYONE">{t.everyone}</option><option value="CLOSE_FRIENDS">{t.closeFriends}</option></select></label>{audience === 'CLOSE_FRIENDS' ? <Link className="font-bold text-brand" to={path('settings/close-friends')}>{t.manageCloseFriends}</Link> : null}{error && <p role="alert">{error}</p>}<button disabled={pending} className="bg-brand px-5 py-3 font-bold text-white disabled:opacity-50">{pending ? t.loading : t.publish}</button></form>{editingFile ? <div className="fixed inset-0 z-50 grid place-items-center overflow-y-auto bg-black/80 p-4" role="dialog" aria-modal="true"><ImageEditor file={editingFile} onSave={(edited) => { setFile(edited); setEditingFile(undefined); }} onCancel={() => setEditingFile(undefined)} /></div> : null}</div>;
}

export function CreateStoryRoute() { return <RequireAuth><CreateStory /></RequireAuth>; }

export function StoryArchive() {
  const { locale } = useI18n(copy); const t = locale === 'en' ? copy.en : copy['pt-BR']; const { value, error, retry } = useStories<{ stories: Story[] }>('/stories/archive', 'archive'); const [selected, setSelected] = useState<string[]>([]); const [title, setTitle] = useState(''); const [cover, setCover] = useState(''); const [editing, setEditing] = useState<string>(); const [highlights, setHighlights] = useState<Highlight[]>([]); const [mutationError, setMutationError] = useState(''); const [deleteTarget, setDeleteTarget] = useState<{ kind: 'story' | 'highlight'; id: string } | null>(null); const reload = () => retry(); const ownerId = value?.stories[0]?.user?.id;
  const archiveRef = useCallback((node: HTMLElement | null) => { if (!node) return; if (!ownerId) { setHighlights([]); return; } const controller = new AbortController(); void api.get<{ highlights: Highlight[] }>(`/stories/highlights/user/${encodeURIComponent(ownerId)}`, { signal: controller.signal }).then((response) => setHighlights(response.highlights)).catch(() => { if (!controller.signal.aborted) setMutationError(t.error); }); return () => controller.abort(); }, [ownerId, value?.stories.length, t.error]);
  const save = async (event: React.FormEvent) => { event.preventDefault(); try { const body = { title, storyIds: selected, coverStoryId: cover }; if (editing) await api.patch(`/stories/highlights/${encodeURIComponent(editing)}`, body); else await api.post('/stories/highlights', body); setSelected([]); setTitle(''); setCover(''); setEditing(undefined); reload(); } catch { setMutationError(t.error); } };
   const remove = async (id: string) => { try { await api.patch(`/stories/${encodeURIComponent(id)}/delete`); reload(); } catch { setMutationError(t.error); } };
   const removeHighlight = async (id: string) => { try { await api.patch(`/stories/highlights/${encodeURIComponent(id)}/delete`); setHighlights((items) => items.filter((item) => item.id !== id)); } catch { setMutationError(t.error); } };
  const editHighlight = (highlight: Highlight) => { setEditing(highlight.id); setTitle(highlight.title); setSelected(highlight.stories.map((story) => story.id)); setCover(highlight.coverStoryId); };
  return <div ref={archiveRef} className="mx-auto min-h-screen max-w-4xl space-y-6 bg-canvas p-6 text-ink"><h1 className="font-display text-3xl font-bold">{t.archive}</h1>{error ? <button role="alert" onClick={retry}>{t.retry}</button> : !value ? <p aria-live="polite">{t.loading}</p> : <><section className="space-y-3"><div className="flex items-center justify-between"><h2 className="font-display text-xl font-bold">{t.highlights}</h2><button onClick={() => { setEditing(undefined); setTitle(''); setSelected([]); setCover(''); }}>{t.newHighlight}</button></div>{highlights.map((highlight) => <article key={highlight.id} className="flex items-center justify-between bg-surface p-3"><span>{highlight.title}</span><span className="flex gap-3"><button onClick={() => editHighlight(highlight)}>{t.edit}</button><button onClick={() => setDeleteTarget({ kind: 'highlight', id: highlight.id })}>{t.delete}</button></span></article>)}</section><div className="grid grid-cols-2 gap-3 sm:grid-cols-4">{value.stories.map((story) => <article key={story.id} className="bg-surface p-2"><button className="block w-full text-left" onClick={() => { if (selected.includes(story.id)) { const next = selected.filter((id) => id !== story.id); setSelected(next); if (cover === story.id) setCover(next[0] ?? ''); } else { setSelected([...selected, story.id]); if (!cover) setCover(story.id); } }} aria-pressed={selected.includes(story.id)}><span className="block aspect-[3/4] overflow-hidden bg-surface-mid"><Media story={story} enabled className="h-full w-full object-cover" /></span><span>{selected.includes(story.id) ? '✓ ' : ''}{new Date(story.createdAt).toLocaleDateString(locale)}</span>{story.viewsCount !== undefined && <span className="block">{t.views}: {story.viewsCount}</span>}</button><button onClick={() => setDeleteTarget({ kind: 'story', id: story.id })} className="mt-2 text-sm text-brand">{t.deleteStory}</button></article>)}</div><form className="space-y-3 bg-surface p-4" onSubmit={save}><label className="block">{t.titleField}<input maxLength={40} required value={title} onChange={(event) => setTitle(event.target.value)} className="ml-3 bg-surface-mid p-2" /></label><fieldset><legend>{t.cover}</legend>{value.stories.filter((story) => selected.includes(story.id)).map((story) => <label key={story.id} className="mr-4"><input type="radio" name="cover" value={story.id} checked={cover === story.id} onChange={() => setCover(story.id)} /> {new Date(story.createdAt).toLocaleDateString(locale)}</label>)}</fieldset><p>{t.chooseStories}</p>{mutationError && <p role="alert">{mutationError}</p>}<button disabled={!selected.length || !cover} className="bg-brand px-4 py-3 text-white">{editing ? t.edit : t.save}</button></form><Dialog open={deleteTarget !== null} onClose={() => setDeleteTarget(null)} title={deleteTarget?.kind === 'story' ? t.deleteStory : t.delete} actions={<><Button variant="secondary" onClick={() => setDeleteTarget(null)}>{t.cancel}</Button><Button variant="danger" onClick={() => { const target = deleteTarget; setDeleteTarget(null); if (target) void (target.kind === 'story' ? remove(target.id) : removeHighlight(target.id)); }}>{t.delete}</Button></>}>{t.confirmDelete}</Dialog></>}</div>;
}

export function HighlightViewer() {
  const { id = '' } = useParams(); const navigate = useNavigate(); const { locale } = useI18n(copy); const t = locale === 'en' ? copy.en : copy['pt-BR']; const { value, error, retry } = useStories<Highlight>(`/stories/highlights/${encodeURIComponent(id)}`, id); const [index, setIndex] = useState(0); const [readyMedia, setReadyMedia] = useState<{ storyId: string; durationMs?: number }>(); const [failedMediaId, setFailedMediaId] = useState<string>(); const [paused, setPaused] = useState(false); const [prevStoryId, setPrevStoryId] = useState<string | undefined>(); const story = value?.stories[index]; const viewed = useRef(new Set<string>()); const ready = isCurrentStoryReady(story?.id, readyMedia?.storyId) && failedMediaId !== story?.id;
  const move = (next: number) => { if (next < 0) navigate(-1); else if (next >= (value?.stories.length ?? 0)) navigate(-1); else setIndex(next); };
  if (story?.id !== prevStoryId) { setPaused(false); setPrevStoryId(story?.id); }
  const highlightViewerRef = useCallback((node: HTMLElement | null) => {
    if (!node || !story) return;
    if (ready && !viewed.current.has(story.id)) { viewed.current.add(story.id); void api.post(`/stories/${encodeURIComponent(story.id)}/view`).catch(() => {}); }
    if (story.mediaType !== 'VIDEO' && shouldAutoAdvanceStory(ready, paused)) {
      const timer = window.setTimeout(() => move(index + 1), storyAdvanceDelayMs('IMAGE'));
      return () => window.clearTimeout(timer);
    }
  }, [story?.id, story?.mediaType, index, ready, paused, value?.stories.length]);
  return <div ref={highlightViewerRef} className="grid min-h-screen place-items-center bg-canvas p-4 text-ink"><section className="relative h-[min(82vh,760px)] w-full max-w-md overflow-hidden bg-surface" onPointerDown={story?.mediaType === 'IMAGE' ? () => setPaused(true) : undefined} onPointerUp={story?.mediaType === 'IMAGE' ? () => setPaused(false) : undefined} onPointerCancel={story?.mediaType === 'IMAGE' ? () => setPaused(false) : undefined} onKeyDown={(event) => { if (event.key === ' ') { event.preventDefault(); setPaused((state) => !state); } }}>{error ? <button onClick={retry} role="alert">{t.retry}</button> : !value ? <p>{t.loading}</p> : !story ? <p>{t.unavailable}</p> : <><Media key={story.id} story={story} enabled paused={paused} className="absolute inset-0 h-full w-full object-contain" onReady={(durationMs) => setReadyMedia({ storyId: story.id, durationMs })} onPlaybackState={(playing) => setPaused(!playing)} onEnded={() => move(index + 1)} onError={() => setFailedMediaId(story.id)} /><div className="absolute inset-x-3 top-3 z-10 flex gap-1" aria-hidden="true">{value.stories.map((entry, position) => <span key={entry.id} className="h-1 flex-1 bg-surface-high"><span className={`story-progress block h-full bg-white ${position < index ? 'scale-x-100' : position === index && ready ? `is-running ${paused ? 'is-paused' : ''}` : ''}`} style={{ animationDuration: `${storyAdvanceDelayMs(story.mediaType, readyMedia?.storyId === story.id ? readyMedia.durationMs : undefined)}ms` }} /></span>)}</div><header className="absolute inset-x-4 top-7 z-10 text-white">{value.title}</header>{failedMediaId === story.id ? <p role="alert" className="absolute inset-x-4 top-16 z-20 bg-surface-high p-3">{t.mediaError}</p> : null}<StoryTextOverlays blocks={story.textBlocks ?? []} /><button className="absolute inset-y-16 left-0 z-10 w-1/3" aria-label={t.previous} onClick={() => move(index - 1)} /><button className="absolute inset-y-16 right-0 z-10 w-1/3" aria-label={t.next} onClick={() => move(index + 1)} />{story.caption ? <p className="absolute inset-x-4 bottom-5 z-10 text-center text-white [text-shadow:0_1px_3px_#000]">{story.caption}</p> : null}</>}</section></div>;
}

export function StoryViewerRoute() { return <RequireAuth><StoryViewer /></RequireAuth>; }
export function StoryArchiveRoute() { return <RequireAuth><StoryArchive /></RequireAuth>; }
export function HighlightViewerRoute() { return <RequireAuth><HighlightViewer /></RequireAuth>; }
