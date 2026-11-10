import { useEffect, useRef } from 'react';
import { chatRepository } from '../repository';

/**
 * View-once lease: armed while an opening exists. A new opening cycle cancels
 * the pending close; a real unmount fires it (deferred). Returns a cancel
 * function for an explicit close.
 */
export function useViewOnceLease({
  openingKey,
  conversationId,
  viewOnceMessageId,
}: {
  openingKey: string | null;
  conversationId?: string;
  viewOnceMessageId?: string;
}) {
  const pendingCloseRef = useRef<{ key: string; cancelled: boolean } | null>(null);

  useEffect(() => {
    if (!(openingKey && conversationId && viewOnceMessageId)) return;
    pendingCloseRef.current = { key: openingKey, cancelled: false };
    return () => {
      const pending = pendingCloseRef.current;
      if (!pending) return;
      pendingCloseRef.current = null;
      Promise.resolve().then(() => {
        if (!pending.cancelled && conversationId && viewOnceMessageId)
          void chatRepository
            .closeViewOnce(conversationId, viewOnceMessageId, pending.key)
            .catch(() => {});
      });
    };
  }, [openingKey, conversationId, viewOnceMessageId]);

  return function cancelPendingClose() {
    const pending = pendingCloseRef.current;
    pendingCloseRef.current = null;
    if (pending) pending.cancelled = true;
  };
}
