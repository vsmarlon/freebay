import { useEffect, useRef, useState } from 'react';
import { api } from '../../core/api';
import { useSession } from '../../core/session';
import { useI18n } from '../../core/locale';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import { chatRepository } from './repository';
import { shouldFetchMedia, type ChatMessage } from './model';

function mediaPath(src: string): string | null {
  if (!src.startsWith('/media/')) return null;
  const url = new URL(src, window.location.origin);
  return url.origin === window.location.origin ? `${url.pathname}${url.search}` : null;
}

export function AuthenticatedMedia({ src, type, alt, enabled = true, conversationId, viewOnceMessage }: {
  src: string;
  type: 'image' | 'video' | 'audio';
  alt?: string;
  enabled?: boolean;
  conversationId?: string;
  viewOnceMessage?: ChatMessage;
}) {
  const { user } = useSession();
  const { t } = useI18n({ en, 'pt-BR': ptBR });
  const isViewOnce = Boolean(viewOnceMessage);
  const [url, setUrl] = useState<string | null>(null);
  const [error, setError] = useState(false);
  const [opening, setOpening] = useState(false);
  const [opened, setOpened] = useState(false);
  const [openedForUser, setOpenedForUser] = useState<string | null>(null);
  const [loadAttempt, setLoadAttempt] = useState(0);
  const [openingKey, setOpeningKey] = useState<string | null>(null);
  const [mediaSrc, setMediaSrc] = useState(src);
  const active = useRef(true);

  useEffect(() => {
    active.current = true;
    return () => { active.current = false; };
  }, []);

  useEffect(() => {
    if (!enabled || !src) return;
    const explicitlyOpenedForCurrentUser = openedForUser === user?.id;
    if (!shouldFetchMedia(isViewOnce, explicitlyOpenedForCurrentUser)) {
      setUrl(null);
      if (isViewOnce && opened) { setOpened(false); setError(false); }
      return;
    }
    const path = mediaPath(isViewOnce ? mediaSrc : src);
    if (!path) { setError(true); return; }
    const controller = new AbortController();
    let objectUrl: string | null = null;
    setError(false);
    void api.blob(path, { signal: controller.signal, ...(isViewOnce && openingKey ? { headers: { 'x-view-once-opening': openingKey } } : {}) }).then((blob) => {
      if (controller.signal.aborted) return;
      objectUrl = URL.createObjectURL(blob);
      setUrl(objectUrl);
    }).catch(() => { if (!controller.signal.aborted) setError(true); });
    return () => {
      controller.abort();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
      setUrl(null);
    };
  }, [src, mediaSrc, enabled, opened, openedForUser, user?.id, isViewOnce, openingKey, loadAttempt]);

  useEffect(() => {
    if (!openingKey || !conversationId || !viewOnceMessage) return;
    const key = openingKey;
    return () => { void chatRepository.closeViewOnce(conversationId, viewOnceMessage.id, key).catch(() => {}); };
  }, [openingKey, conversationId, viewOnceMessage?.id]);

  async function openOnce() {
    if (!conversationId || !viewOnceMessage || opening || viewOnceMessage.senderId === user?.id) return;
    if (opened && openedForUser === user?.id) { setError(false); setLoadAttempt((attempt) => attempt + 1); return; }
    setOpening(true);
    try {
      const key = openingKey ?? crypto.randomUUID();
      setOpeningKey(key);
      const result = await chatRepository.openViewOnce(conversationId, viewOnceMessage.id, key);
      if (!active.current) { await chatRepository.closeViewOnce(conversationId, viewOnceMessage.id, key).catch(() => {}); return; }
      setMediaSrc(result.mediaUrl);
      setOpenedForUser(user?.id ?? null);
      setOpened(true);
    } catch { setError(true); }
    finally { if (active.current) setOpening(false); }
  }

  useEffect(() => {
    if (!openedForUser || openedForUser === user?.id) return;
    if (openingKey && conversationId && viewOnceMessage) void chatRepository.closeViewOnce(conversationId, viewOnceMessage.id, openingKey).catch(() => {});
    setOpeningKey(null); setOpened(false); setOpenedForUser(null); setUrl(null); setMediaSrc(src); setError(false);
  }, [openedForUser, user?.id, openingKey, conversationId, viewOnceMessage, src]);

  function closeOnce() {
    setOpeningKey(null); setOpened(false); setOpenedForUser(null); setUrl(null); setMediaSrc(src); setError(false);
  }

  if (viewOnceMessage && !src) return <p role="status" className="text-sm text-muted">{t('chat.mediaError')}</p>;
  if (viewOnceMessage && viewOnceMessage.senderId === user?.id) return <p role="status" className="text-sm text-muted">{t('chat.viewOnceSenderDenied')}</p>;
  if (viewOnceMessage && (!opened || error)) return <button className="ui-button ui-secondary" type="button" onClick={openOnce} disabled={opening}>{error ? t('common.retry') : opening ? t('common.loading') : t('chat.viewOnce')}</button>;
  if (error) return <p role="alert" className="text-sm text-muted">{t('chat.mediaError')}</p>;
  if (!url) return <span role="status" className="text-sm text-muted">{t('common.loading')}</span>;
  return <>{type === 'video' ? <video className="max-h-96 max-w-full" src={url} controls preload="metadata" /> : type === 'audio' ? <audio src={url} controls preload="metadata" /> : <img className="max-h-96 max-w-full object-contain" src={url} alt={alt ?? ''} />}{viewOnceMessage ? <button type="button" className="ui-button ui-ghost" onClick={closeOnce}>{t('common.close')}</button> : null}</>;
}
