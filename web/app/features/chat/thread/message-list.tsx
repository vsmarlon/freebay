import type { Ref } from 'react';
import { useI18n } from '../../../core/locale';
import { MessageItem } from '../message-item';
import { chatCatalogs } from '../catalogs';
import type { ChatMessage, Transcript } from '../model';
import type { MessageSelection } from '../hooks/use-message-selection';

export function MessageList({
  conversationId,
  locale,
  messages,
  page,
  viewer,
  selection,
  scrollRef,
  transcript,
  actions,
}: {
  conversationId: string;
  locale: string;
  messages: ChatMessage[];
  page: Transcript | undefined;
  viewer: { id?: string; avatarUrl?: string | null; displayName?: string };
  selection: MessageSelection;
  scrollRef: Ref<HTMLDivElement>;
  transcript: {
    backgroundImage: string | null;
    hasOlder: boolean;
    loadingOlder: boolean;
    empty: boolean;
  };
  actions: {
    loadOlder: () => void;
    reply: (message: ChatMessage) => void;
    openExternal: (url: string) => void;
  };
}) {
  const { t } = useI18n(chatCatalogs);
  return (
    <section
      ref={scrollRef}
      aria-label={t('chat.thread')}
      className="mt-2 flex min-h-0 min-w-0 flex-1 flex-col gap-2 overflow-x-hidden overflow-y-auto border border-(--hairline) p-2 sm:p-4"
      style={
        transcript.backgroundImage
          ? { backgroundImage: `url("${transcript.backgroundImage}")`, backgroundSize: 'cover' }
          : undefined
      }
    >
      {transcript.hasOlder ? (
        <button
          className="ui-button ui-secondary self-center"
          type="button"
          disabled={transcript.loadingOlder}
          onClick={actions.loadOlder}
        >
          {t('chat.loadOlder')}
        </button>
      ) : null}
      {messages.map((message) => (
        <MessageItem
          key={message.id}
          message={message}
          conversationId={conversationId}
          locale={locale}
          userId={viewer.id}
          userAvatar={viewer.avatarUrl ?? null}
          userName={viewer.displayName ?? ''}
          otherName={page?.otherUser.displayName ?? ''}
          otherAvatar={page?.otherUser.avatarUrl ?? null}
          selected={selection.selectedIds.includes(message.id)}
          onToggle={selection.toggle}
          onReply={(target) => {
            actions.reply(target);
            selection.clear();
          }}
          onOpenExternal={actions.openExternal}
        />
      ))}
      {!messages.length && transcript.empty ? (
        <p className="m-auto text-muted">{t('chat.emptyThread')}</p>
      ) : null}
    </section>
  );
}
