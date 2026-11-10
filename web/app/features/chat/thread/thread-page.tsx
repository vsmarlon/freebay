import { useState } from 'react';
import { useSession } from '../../../core/session';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';
import type { ChatMessage } from '../model';
import {
  conversationRecordFrom,
  threadMessages,
  useChatSidebar,
  useConversationRecord,
  useThreadTranscript,
} from '../queries';
import { useChatSocket } from '../hooks/use-chat-socket';
import { useMessageSelection } from '../hooks/use-message-selection';
import { usePresenceHidden } from '../hooks/use-presence-hidden';
import { useScrollAnchor } from '../hooks/use-scroll-anchor';
import { MessageList } from './message-list';
import { SelectionBar } from './selection-bar';
import { ThreadComposer } from './thread-composer';
import { ThreadDialogs } from './thread-dialogs';
import { ThreadHeader } from './thread-header';
import { ThreadSidebar } from './thread-sidebar';
import { useThreadActions } from './use-thread-actions';
import { useThreadBackground } from './use-thread-background';
import { useThreadOverlays } from './use-thread-overlays';

export function ThreadPage({ conversationId, locale }: { conversationId: string; locale: string }) {
  const session = useSession();
  const { t } = useI18n(chatCatalogs);
  const transcript = useThreadTranscript(conversationId);
  const pages = transcript.data?.pages;
  const page = pages?.[0];
  const messages = pages ? threadMessages(pages) : [];
  const recordQuery = useConversationRecord(conversationId, page?.otherUser.displayName);
  const record = conversationRecordFrom(recordQuery.data, conversationId);
  const sidebar = useChatSidebar();
  const socket = useChatSocket(conversationId, page?.otherUserId, session.user?.id);
  const selection = useMessageSelection();
  const [reply, setReply] = useState<ChatMessage | null>(null);
  const [sending, setSending] = useState(false);
  const overlays = useThreadOverlays();
  const actions = useThreadActions({ conversationId, page });
  const background = useThreadBackground(conversationId, page?.preference?.backgroundUrl);
  const presence = usePresenceHidden(session.user?.id, conversationId);
  const { scrollNodeRef, capture: captureScroll } = useScrollAnchor(messages.length);

  async function loadOlder() {
    if (!transcript.hasNextPage || sending) return;
    captureScroll();
    try {
      await transcript.fetchNextPage();
    } catch {
      actions.setError(t('chat.loadError'));
    }
  }

  function togglePresence() {
    if (presence.toggle() === null) actions.setError(t('chat.sendError'));
  }

  const status =
    page?.threadType === 'ORDER'
      ? t('chat.order')
      : record?.status === 'PENDING'
        ? t('chat.pending')
        : page
          ? t('chat.direct')
          : undefined;
  const error =
    actions.error ||
    socket.joinError ||
    (transcript.isError ? t('chat.loadError') : '') ||
    background.error;
  const reactionTargets = messages.filter(
    (message) => selection.selectedIds.includes(message.id) && !message.deletedAt,
  );

  return (
    <div className="mx-auto grid min-h-0 min-w-0 w-full flex-1 grid-cols-1 grid-rows-[minmax(0,1fr)] gap-3 p-3 text-ink sm:p-6 md:grid-cols-[320px_minmax(0,1fr)]">
      <ThreadSidebar conversations={sidebar.data?.items ?? []} activeId={conversationId} />
      <section className="flex min-h-0 min-w-0 flex-col">
        <ThreadHeader
          page={page}
          record={record}
          presence={{
            muted: actions.muted,
            hidden: presence.hidden,
            online: socket.online,
            typing: socket.typing,
            status,
          }}
          actions={{
            openDetails: overlays.openDetails,
            openGallery: () => overlays.setGalleryKind('IMAGE'),
            openStarred: overlays.openStarred,
            toggleArchive: () => void actions.toggleArchive(),
            deleteConversation: () => overlays.openConfirmation('deleteConversation'),
          }}
        />
        {socket.offline ? <ThreadNotice role="status" text={t('chat.socketOffline')} /> : null}
        {error ? <ThreadNotice role="alert" text={error} /> : null}
        {record?.canAccept === true ? (
          <button
            className="ui-button ui-primary mt-2"
            type="button"
            onClick={() => void actions.acceptConversation()}
          >
            {t('chat.accept')}
          </button>
        ) : null}
        <MessageList
          conversationId={conversationId}
          locale={locale}
          messages={messages}
          page={page}
          viewer={session.user ?? {}}
          selection={selection}
          scrollRef={scrollNodeRef}
          transcript={{
            backgroundImage: background.image,
            hasOlder: Boolean(transcript.hasNextPage),
            loadingOlder: transcript.isFetchingNextPage,
            empty: !error,
          }}
          actions={{
            loadOlder: () => void loadOlder(),
            reply: setReply,
            openExternal: actions.openExternal,
          }}
        />
        <SelectionBar
          conversationId={conversationId}
          messages={messages}
          selection={selection}
          onReply={setReply}
          onError={actions.setError}
        />
        <ThreadComposer
          conversationId={conversationId}
          locale={locale}
          inquiry={{
            ready: Boolean(page && record),
            productId: record?.product?.id,
            otherUserId: page?.otherUserId,
          }}
          reply={reply}
          onReplyChange={setReply}
          typing={{
            emitDraftActivity: socket.emitDraftActivity,
            emitStopTyping: socket.emitStopTyping,
          }}
          reaction={
            reactionTargets.length === 1
              ? {
                  message: reactionTargets[0],
                  onSelect: (emoji) => void actions.toggleReaction(reactionTargets[0], emoji),
                }
              : undefined
          }
          onError={actions.setError}
          onSendingChange={setSending}
        />
      </section>
      <ThreadDialogs
        conversationId={conversationId}
        page={page}
        presenceHidden={presence.hidden}
        overlays={overlays}
        background={background}
        actions={actions}
        onTogglePresence={togglePresence}
      />
    </div>
  );
}

function ThreadNotice({ role, text }: { role: 'alert' | 'status'; text: string }) {
  return (
    <p
      role={role}
      className={`mt-2 p-2 text-sm ${role === 'alert' ? 'bg-surface-high' : 'bg-surface-mid'}`}
    >
      {text}
    </p>
  );
}
