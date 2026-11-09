import { useCallback, useRef, useState, type CSSProperties, type MouseEvent } from 'react';
import { api } from '../core/api';
import { Icon } from './index';

const fmt = (seconds: number): string => {
  if (!Number.isFinite(seconds) || seconds < 0) return '0:00';
  const total = Math.floor(seconds);
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, '0')}`;
};

export function VoicePlayer({ src, playLabel, pauseLabel, seekLabel, fallbackLabel }: {
  src: string;
  playLabel: string;
  pauseLabel: string;
  seekLabel: string;
  fallbackLabel: string;
}) {
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0); // 0..1
  const [current, setCurrent] = useState(0); // seconds
  const [duration, setDuration] = useState(0);
  const [failed, setFailed] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const mount = useCallback((node: HTMLAudioElement | null) => {
    audioRef.current = node;
    if (!node) return;
    if (!src.startsWith('/media/')) { setFailed(true); return; }
    let objectUrl: string | null = null;
    const controller = new AbortController();
    const onTime = () => { setCurrent(node.currentTime); setProgress(node.duration ? node.currentTime / node.duration : 0); };
    const onMeta = () => setDuration(node.duration);
    const onPlay = () => setPlaying(true);
    const onPause = () => setPlaying(false);
    const onEnd = () => { setPlaying(false); setProgress(0); setCurrent(0); };
    node.addEventListener('timeupdate', onTime);
    node.addEventListener('loadedmetadata', onMeta);
    node.addEventListener('play', onPlay);
    node.addEventListener('pause', onPause);
    node.addEventListener('ended', onEnd);
    setFailed(false); setPlaying(false); setProgress(0); setCurrent(0); setDuration(0);
    void api.blob(src, { signal: controller.signal }).then((blob) => {
      if (controller.signal.aborted) return;
      objectUrl = URL.createObjectURL(blob);
      node.src = objectUrl;
    }).catch(() => { if (!controller.signal.aborted) setFailed(true); });
    return () => {
      controller.abort();
      node.removeEventListener('timeupdate', onTime);
      node.removeEventListener('loadedmetadata', onMeta);
      node.removeEventListener('play', onPlay);
      node.removeEventListener('pause', onPause);
      node.removeEventListener('ended', onEnd);
      node.removeAttribute('src');
      node.load();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
      if (audioRef.current === node) audioRef.current = null;
    };
  }, [src]);

  function toggle() {
    const audio = audioRef.current;
    if (!audio) return;
    if (audio.paused) void audio.play().catch(() => setFailed(true));
    else audio.pause();
  }

  function seek(event: MouseEvent<HTMLDivElement>) {
    const audio = audioRef.current;
    if (!audio || !duration) return;
    const rect = event.currentTarget.getBoundingClientRect();
    const fraction = Math.min(1, Math.max(0, (event.clientX - rect.left) / rect.width));
    audio.currentTime = fraction * duration;
    setProgress(fraction); setCurrent(fraction * duration);
  }

  if (failed) return <p className="text-xs text-muted">{fallbackLabel}</p>;
  return <div className="voice-player">
    <audio ref={mount} preload="metadata" />
    <button type="button" className="icon-control" aria-label={playing ? pauseLabel : playLabel} title={playing ? pauseLabel : playLabel} onClick={toggle}><Icon name={playing ? 'pause' : 'play'} size={16} /></button>
    <div className="voice-track" role="slider" aria-label={seekLabel} aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(progress * 100)} onClick={seek}><div className="voice-track-progress" style={{ '--progress': `${progress * 100}%` } as CSSProperties} /></div>
    <span className="voice-time">{fmt(current)} / {fmt(duration)}</span>
  </div>;
}
