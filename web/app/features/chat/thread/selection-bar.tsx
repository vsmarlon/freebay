import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Button, Dialog, Icon } from '../../../components';
import { useI18n } from '../../../core/locale';
import { useSession } from '../../../core/session';
import { chatCatalogs } from '../catalogs';
import { type ChatMessage } from '../model';
import { deleteThreadMessages } from '../queries';
import { chatRepository } from '../repository';
import type { MessageSelection } from '../hooks/use-message-selection';
import { ForwardTargets } from './forward-targets';

export function SelectionBar({
  conversationId,
  messages,
  selection,
  onReply,
  onError,
}: {
  conversationId: string;
  messages: ChatMessage[];
  selection: MessageSelection;
  onReply: (message: ChatMessage) => void;
  onError: (message: string) => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const { user } = useSession();
  const client = useQueryClient();
  const [forwardOpen, setForwardOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  const selected = messages.filter((message) => selection.selectedIds.includes(message.id));
  const shareableText = selected
    .filter((message) => !message.viewOnce && !message.deletedAt)
    .map((message) => message.content ?? '')
    .filter(Boolean)
    .join('\n');

  async function copy() {
    if (!shareableText) return;
    try {
      await navigator.clipboard.writeText(shareableText);
      selection.clear();
    } catch {
      onError(t('chat.clipboardError'));
    }
  }

  async function share() {
    if (!shareableText || !navigator.share) {
      onError(t('chat.shareUnsupported'));
      return;
    }
    try {
      await navigator.share({ text: shareableText });
      selection.clear();
    } catch (cause) {
      if (!(cause instanceof DOMException && cause.name === 'AbortError'))
        onError(t('chat.sendError'));
    }
  }

  async function star() {
    try {
      for (const messageId of selection.selectedIds)
        await chatRepository.star(conversationId, messageId);
      selection.clear();
    } catch {
      onError(t('chat.sendError'));
    }
  }

  async function remove() {
    const deletable = selected.filter(
      (message) => message.senderId === user?.id && !message.deletedAt,
    );
    const settled = await Promise.allSettled(
      deletable.map((message) => chatRepository.deleteMessage(conversationId, message.id)),
    );
    const removed = deletable
      .filter((_, index) => settled[index].status === 'fulfilled')
      .map((message) => message.id);
    if (removed.length) deleteThreadMessages(client, conversationId, removed);
    selection.clear();
    if (settled.some((result) => result.status === 'rejected')) onError(t('chat.sendError'));
  }

  if (!selection.selectedIds.length) return null;
  return (
    <div className="flex flex-wrap items-center gap-2 bg-surface-mid p-2 text-sm">
      <span>{t('chat.selected', { count: selection.selectedIds.length })}</span>
      <button className="icon-control icon-control-sm" type="button" onClick={selection.clear}>
        <Icon name="close" size={16} />
        <span className="sr-only">{t('chat.cancel')}</span>
      </button>
      <button
        className="icon-control icon-control-sm"
        type="button"
        onClick={() => {
          if (selected.length === 1) onReply(selected[0]);
          selection.clear();
        }}
        aria-label={t('chat.reply')}
        title={t('chat.reply')}
      >
        <Icon name="reply" size={16} />
      </button>
      <button
        className="icon-control icon-control-sm"
        type="button"
        onClick={() => void star()}
        aria-label={t('chat.star')}
        title={t('chat.star')}
      >
        <Icon name="bookmark" size={16} />
      </button>
      <button
        className="icon-control icon-control-sm"
        type="button"
        onClick={() => void copy()}
        aria-label={t('chat.copy')}
        title={t('chat.copy')}
      >
        <Icon name="doc" size={16} />
      </button>
      <button
        className="icon-control icon-control-sm"
        type="button"
        onClick={() => void share()}
        aria-label={t('chat.share')}
        title={t('chat.share')}
      >
        <Icon name="send" size={16} />
      </button>
      <button
        className="icon-control icon-control-sm"
        type="button"
        onClick={() => setForwardOpen((open) => !open)}
        aria-label={t('chat.chooseRecipients')}
        title={t('chat.chooseRecipients')}
      >
        <Icon name="repeat" size={16} />
      </button>
      <button
        className="icon-control icon-control-sm"
        type="button"
        onClick={() => setConfirmDelete(true)}
        aria-label={t('chat.deleteSelected')}
        title={t('chat.deleteSelected')}
      >
        <Icon name="trash" size={16} />
      </button>
      <ForwardTargets
        open={forwardOpen}
        conversationId={conversationId}
        messages={messages}
        selection={selection}
        onError={onError}
      />
      <Dialog
        open={confirmDelete}
        onClose={() => setConfirmDelete(false)}
        title={t('chat.deleteSelected')}
        actions={
          <>
            <Button variant="secondary" onClick={() => setConfirmDelete(false)}>
              {t('common.cancel')}
            </Button>
            <Button
              variant="danger"
              onClick={() => {
                setConfirmDelete(false);
                void remove();
              }}
            >
              {t('common.delete')}
            </Button>
          </>
        }
      >
        {t('chat.confirmDeleteSelected')}
      </Dialog>
    </div>
  );
}
