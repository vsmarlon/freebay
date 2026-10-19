import { useEffect, useState } from 'react';
import { api } from './api';
import { useSession } from './session';
import { useI18n } from './locale';

export function mediaUrl(src: string): string { const url = new URL(src, typeof window === 'undefined' ? 'https://freebay.invalid' : window.location.origin); if (!['http:', 'https:'].includes(url.protocol)) throw new TypeError('Unsupported media URL'); return url.origin === 'https://freebay.invalid' ? `${url.pathname}${url.search}` : url.toString(); }
export function useMediaUrl(src: string | null | undefined, enabled = true) {
  const { user, isSigningOut } = useSession();
  const [resolved, setResolved] = useState<{ userId: string; src: string; pending: boolean; url?: string; error?: unknown } | null>(null);
  const userId = user?.id;
  useEffect(() => {
    if (!src || !enabled || !userId || isSigningOut) { setResolved(null); return; }
    const controller = new AbortController(); let objectUrl: string | null = null;
    setResolved({ userId, src, pending: true });
    void api.blob(src, { signal: controller.signal }).then((blob) => {
      if (!controller.signal.aborted) { objectUrl = URL.createObjectURL(blob); setResolved({ userId, src, pending: false, url: objectUrl }); }
    }).catch((error: unknown) => {
      if (!controller.signal.aborted) setResolved({ userId, src, pending: false, error });
    });
    return () => { controller.abort(); if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [enabled, isSigningOut, src, userId]);
  const current = resolved && resolved.userId === userId && resolved.src === src && enabled && !isSigningOut ? resolved : null;
  return { url: current?.url ?? null, isPending: current?.pending ?? false, error: current?.error };
}
export function AuthenticatedMedia({ src, type, alt = '', enabled = true, className }: { src: string | null | undefined; type: 'image' | 'video' | 'audio'; alt?: string; enabled?: boolean; className?: string }) {
  const media = useMediaUrl(src, enabled); const { t } = useI18n();
  if (!media.url) return media.isPending ? <span role="status">{t('common.loading')}</span> : media.error ? <span role="alert">{t('common.error')}</span> : null;
  if (type === 'image') return <img src={media.url} alt={alt} className={className} />;
  if (type === 'video') return <video src={media.url} controls className={className} />;
  return <audio src={media.url} controls className={className} />;
}
