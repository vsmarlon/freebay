import { useCallback, useRef, useState } from 'react';
import { useI18n } from '../core/locale';
import type { FFmpeg } from '@ffmpeg/ffmpeg';

// ponytail: ffmpeg.wasm trims faster-than-realtime but fetches a ~31 MB wasm core on first use, cached per session.
// Loaded only from a user-driven save, so SSR never evaluates it. Worker comes pre-bundled via ?worker&url;
// the wasm core is the only CDN dependency. Self-host both if CDN uptime is ever a concern.
const minTrimSeconds = 0.2;
const coreBase = 'https://cdn.jsdelivr.net/npm/@ffmpeg/core@0.12.10/dist/esm';

/** Clamps a trim window into the video and reports whether it differs from the untouched video. */
export function trimWindow(start: number, end: number, duration: number) {
  const length = Number.isFinite(duration) && duration > 0 ? duration : 0;
  const from = Math.min(Math.max(0, start), length);
  const to = Math.min(Math.max(from, end), length);
  if (to - from < minTrimSeconds || (from <= 0.05 && to >= length - 0.05)) return { start: 0, end: length, changed: false };
  return { start: from, end: to, changed: true };
}

export function trimmedFileName(sourceName: string, type: string) {
  return `${sourceName.replace(/\.[^.]+$/, '') || 'story'}-trimmed.${type.includes('mp4') ? 'mp4' : 'webm'}`;
}

/** FFmpeg and its wasm core load once per session; a failed load drops the cache so the next save retries. */
let ffmpegInstance: Promise<FFmpeg> | null = null;
const loadedFFmpeg = (): Promise<FFmpeg> => (ffmpegInstance ??= (async () => {
  const [{ FFmpeg: Engine }, { toBlobURL }] = await Promise.all([import('@ffmpeg/ffmpeg'), import('@ffmpeg/util')]);
  const [{ default: workerUrl }, coreURL, wasmURL] = await Promise.all([
    import('@ffmpeg/ffmpeg/worker?worker&url'),
    toBlobURL(`${coreBase}/ffmpeg-core.js`, 'text/javascript'),
    toBlobURL(`${coreBase}/ffmpeg-core.wasm`, 'application/wasm'),
  ]);
  const ffmpeg = new Engine();
  await ffmpeg.load({ classWorkerURL: workerUrl, coreURL, wasmURL });
  return ffmpeg;
})().catch((error) => { ffmpegInstance = null; throw error; }));

const terminateFFmpeg = () => { if (!ffmpegInstance) return; const pending = ffmpegInstance; ffmpegInstance = null; void pending.then((ffmpeg) => { try { ffmpeg.terminate(); } catch { /* already dead */ } }).catch(() => {}); };

type VideoEditorProps = { file: File; onSave: (file: File) => void; onCancel: () => void };

export function VideoEditor({ file, onSave, onCancel }: VideoEditorProps) {
  const { t } = useI18n();
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const objectUrlRef = useRef('');
  const abortRef = useRef<(() => void) | null>(null);
  const [start, setStart] = useState(0);
  const [end, setEnd] = useState<number | null>(null);
  const [duration, setDuration] = useState(0);
  const [muted, setMuted] = useState(false);
  const [busy, setBusy] = useState(false);
  const [percent, setPercent] = useState(0);
  const [error, setError] = useState('');

  const attachVideo = useCallback((node: HTMLVideoElement | null) => {
    if (node) {
      videoRef.current = node;
      if (!node.src) node.src = objectUrlRef.current || (objectUrlRef.current = URL.createObjectURL(file));
    } else {
      abortRef.current?.();
      if (objectUrlRef.current) URL.revokeObjectURL(objectUrlRef.current);
      objectUrlRef.current = '';
    }
  }, [file]);
  const markStart = () => { const video = videoRef.current; if (!video) return; setStart(Math.max(0, Math.min(video.currentTime, (end ?? video.duration) - minTrimSeconds))); };
  const markEnd = () => { const video = videoRef.current; if (!video) return; setEnd(Math.min(video.duration, Math.max(video.currentTime, start + minTrimSeconds))); };
  const toggleMute = () => { const next = !muted; setMuted(next); if (videoRef.current) videoRef.current.muted = next; };
  const save = async () => {
    const video = videoRef.current;
    if (!video || busy) return;
    const segment = trimWindow(start, end ?? video.duration, video.duration);
    if (!segment.changed && !muted) { onSave(file); return; } // ponytail: untouched video keeps the original file, no re-encode
    setBusy(true); setPercent(0); setError('');
    let aborted = false;
    abortRef.current = () => { aborted = true; terminateFFmpeg(); };
    try {
      const ffmpeg = await loadedFFmpeg();
      const onProgress = (event: { progress?: number }) => { if (typeof event.progress === 'number') setPercent(Math.min(100, Math.max(0, Math.round(event.progress * 100)))); };
      ffmpeg.on('progress', onProgress);
      try {
        const input = `input${file.name.match(/\.\w+$/)?.[0] ?? '.mp4'}`;
        const output = 'story-trimmed.mp4';
        const { fetchFile } = await import('@ffmpeg/util');
        await ffmpeg.writeFile(input, await fetchFile(file));
        const args = ['-ss', segment.start.toFixed(3), '-i', input, '-t', (segment.end - segment.start).toFixed(3)];
        if (muted) args.push('-an');
        args.push('-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '23', '-maxrate', '2500k', '-bufsize', '5M', '-pix_fmt', 'yuv420p');
        if (!muted) args.push('-c:a', 'aac', '-b:a', '128k');
        args.push('-movflags', '+faststart', '-f', 'mp4', output);
        const code = await ffmpeg.exec(args, 120_000);
        if (code !== 0) throw new TypeError(`FFmpeg exited with code ${code}`);
        const data = await ffmpeg.readFile(output);
        if (typeof data === 'string' || !data.length) throw new TypeError('ffmpeg produced no video data');
        await ffmpeg.deleteFile(input).catch(() => {});
        await ffmpeg.deleteFile(output).catch(() => {});
        // copy through a plain ArrayBuffer-backed view: ffmpeg hands back SharedArrayBuffer-capable views
        onSave(new File([new Uint8Array(data)], trimmedFileName(file.name, 'video/mp4'), { type: 'video/mp4', lastModified: Date.now() }));
      } finally { ffmpeg.off('progress', onProgress); }
    } catch {
      if (!aborted) setError(t('mediaEditor.unsupported'));
    } finally {
      setBusy(false); setPercent(0); abortRef.current = null;
    }
  };

  const segment = trimWindow(start, end ?? duration, duration);
  return <section className="grid max-w-full gap-3 p-4" aria-label={`${t('mediaEditor.videoTitle')} (${file.name})`}>
    <video ref={attachVideo} controls playsInline preload="metadata" className="mx-auto block max-h-[60vh] w-full bg-black object-contain" onLoadedMetadata={(event) => { if (Number.isFinite(event.currentTarget.duration)) setDuration(event.currentTarget.duration); }} />
    <div className="flex flex-wrap gap-2">
      <button type="button" className="min-h-8 cursor-pointer border border-ink bg-surface px-3.5 py-2 font-display text-[13px] font-bold text-ink disabled:cursor-not-allowed disabled:opacity-50" disabled={busy} onClick={markStart}>{t('mediaEditor.trimStart')}</button>
      <button type="button" className="min-h-8 cursor-pointer border border-ink bg-surface px-3.5 py-2 font-display text-[13px] font-bold text-ink disabled:cursor-not-allowed disabled:opacity-50" disabled={busy} onClick={markEnd}>{t('mediaEditor.trimEnd')}</button>
      <button type="button" className="min-h-8 cursor-pointer border border-ink bg-surface px-3.5 py-2 font-display text-[13px] font-bold text-ink disabled:cursor-not-allowed disabled:opacity-50" aria-pressed={muted} disabled={busy} onClick={toggleMute}>{t('mediaEditor.mute')}</button>
    </div>
    <p className="text-muted">{t('mediaEditor.segment')}: {(segment.end - segment.start).toFixed(1)}s</p>
    {busy ? <p role="status">{percent ? t('mediaEditor.processing', { percent }) : t('mediaEditor.saving')}</p> : null}
    {error ? <p role="alert">{error}</p> : null}
    <footer>
      <button type="button" className="min-h-10 cursor-pointer border border-ink bg-surface px-3.5 py-2 font-display text-[13px] font-bold text-ink disabled:cursor-not-allowed disabled:opacity-50" disabled={busy} onClick={onCancel}>{t('common.cancel')}</button>
      <button type="button" className="min-h-10 cursor-pointer border border-ink bg-linear-to-br from-[#660062] to-brand px-3.5 py-2 font-display text-[13px] font-bold text-white shadow-[3px_3px_#660062] disabled:cursor-not-allowed disabled:opacity-50" disabled={busy} onClick={() => void save()}>{t('common.save')}</button>
    </footer>
  </section>;
}
