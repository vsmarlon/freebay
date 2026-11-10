import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../../core/api';
import { useSession } from '../../core/session';
import { useI18n } from '../../core/locale';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import { chatRepository } from './repository';
import { shouldFetchMedia } from './model';
import { useViewOnceLease } from './hooks/use-view-once-lease';

function mediaPath(src: string): string | null {
  if (!src.startsWith('/media/')) return null;
  const url = new URL(src, window.location.origin);
  return url.origin === window.location.origin ? `${url.pathname}${url.search}` : null;
}

export function AuthenticatedMedia({
  src,
  type,
  alt,
  enabled = true,
  conversationId,
  viewOnceMessageId,
  viewOnceSenderId,
}: {
  src: string;
  type: 'image' | 'video' | 'audio';
  alt?: string;
  enabled?: boolean;
  conversationId?: string;
  viewOnceMessageId?: string;
  viewOnceSenderId?: string;
}) {
  const { user } = useSession();
  const { t } = useI18n({ en, 'pt-BR': ptBR });
  const isViewOnce = Boolean(viewOnceMessageId);
  const [opened, setOpened] = useState(false);
  const [opening, setOpening] = useState(false);
  const [openingKey, setOpeningKey] = useState<string | null>(null);
  const [openedMediaUrl, setOpenedMediaUrl] = useState<string | null>(null);
  const [openError, setOpenError] = useState(false);
  const cancelViewOnceLease = useViewOnceLease({
    openingKey,
    conversationId,
    viewOnceMessageId,
  });

  const activeSrc = isViewOnce ? (opened ? (openedMediaUrl ?? '') : '') : src;
  const wantsMedia = enabled && Boolean(activeSrc) && shouldFetchMedia(isViewOnce, opened);
  const fetchPath = wantsMedia ? mediaPath(activeSrc) : null;
  const canFetch = wantsMedia && Boolean(fetchPath);

  // The blob fetch is a query: state comes back scoped to the resolved key, and
  // the root cache subscription revokes the object URL when the entry is removed.
  const blobQuery = useQuery({
    // ['media', …] keys ride the root cache subscription that revokes the object
    // URL when the entry is removed (gc).
    queryKey: [
      'media',
      'chat-media',
      user?.id ?? '',
      fetchPath ?? '',
      isViewOnce && openingKey ? openingKey : '',
    ],
    enabled: canFetch && Boolean(user),
    queryFn: async ({ signal }) => {
      const blob = await api.blob(fetchPath!, {
        signal,
        ...(isViewOnce && openingKey ? { headers: { 'x-view-once-opening': openingKey } } : {}),
      });
      return URL.createObjectURL(blob);
    },
    staleTime: 0,
    gcTime: 0,
    retry: false,
  });
  const mediaUrl = canFetch ? (blobQuery.data ?? null) : null;
  const visualError = (canFetch && Boolean(blobQuery.error)) || openError;

  // View-once lease: armed while an opening exists; the next opening cycle
  // cancels the pending close, a real unmount fires it (deferred).

  async function openOnce() {
    if (!conversationId || !viewOnceMessageId || opening || viewOnceSenderId === user?.id) return;
    // Already opened for this viewer: the take reachable by refetch (retry) only.
    if (opened) {
      void blobQuery.refetch();
      return;
    }
    setOpenError(false);
    setOpening(true);
    try {
      const key = openingKey ?? crypto.randomUUID();
      setOpeningKey(key);
      const result = await chatRepository.openViewOnce(conversationId, viewOnceMessageId, key);
      // A close/unmount racing the response fires the server lease release below.
      setOpenedMediaUrl(result.mediaUrl);
      setOpened(true);
    } catch {
      setOpenError(true);
    } finally {
      setOpening(false);
    }
  }

  function closeOnce() {
    cancelViewOnceLease();
    setOpeningKey(null);
    setOpened(false);
    setOpenedMediaUrl(null);
    setOpenError(false);
    if (openingKey && conversationId && viewOnceMessageId)
      void chatRepository
        .closeViewOnce(conversationId, viewOnceMessageId, openingKey)
        .catch(() => {});
  }

  const content =
    viewOnceMessageId && !src ? (
      <p role="status" className="text-sm text-muted">
        {t('chat.mediaError')}
      </p>
    ) : viewOnceMessageId && viewOnceSenderId === user?.id ? (
      <p role="status" className="text-sm text-muted">
        {t('chat.viewOnceSenderDenied')}
      </p>
    ) : viewOnceMessageId && (!opened || visualError) ? (
      <button
        className="ui-button ui-secondary"
        type="button"
        onClick={() => void openOnce()}
        disabled={opening}
      >
        {visualError ? t('common.retry') : opening ? t('common.loading') : t('chat.viewOnce')}
      </button>
    ) : visualError ? (
      <p role="alert" className="text-sm text-muted">
        {t('chat.mediaError')}
      </p>
    ) : !mediaUrl ? (
      <span role="status" className="text-sm text-muted">
        {t('common.loading')}
      </span>
    ) : (
      <>
        {type === 'video' ? (
          <video className="max-h-96 max-w-full" src={mediaUrl} controls preload="metadata" />
        ) : type === 'audio' ? (
          <audio src={mediaUrl} controls preload="metadata" />
        ) : (
          <img className="max-h-96 max-w-full object-contain" src={mediaUrl} alt={alt ?? ''} />
        )}
        {viewOnceMessageId ? (
          <button type="button" className="ui-button ui-ghost" onClick={closeOnce}>
            {t('common.close')}
          </button>
        ) : null}
      </>
    );
  return <span style={{ display: 'contents' }}>{content}</span>;
}
