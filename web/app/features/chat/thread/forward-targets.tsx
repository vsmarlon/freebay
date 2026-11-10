import { useState } from 'react';
import { useDebouncedValue } from '../../../core/use-debounced-value';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';
import { canForwardSelection, type ChatMessage, type Conversation } from '../model';
import { useForwardTargets } from '../queries';
import { chatRepository } from '../repository';
import type { MessageSelection } from '../hooks/use-message-selection';

export function ForwardTargets({
  open,
  conversationId,
  messages,
  selection,
  onError,
}: {
  open: boolean;
  conversationId: string;
  messages: ChatMessage[];
  selection: MessageSelection;
  onError: (message: string) => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const [search, setSearch] = useState('');
  const query = useForwardTargets(useDebouncedValue(search, 180), open);
  if (!open) return null;
  const selected = messages.filter((message) => selection.selectedIds.includes(message.id));

  async function forward() {
    const hasDeleted =
      selected.some((message) => message.deletedAt !== null) ||
      selected.length !== selection.selectedIds.length;
    if (
      !canForwardSelection(
        selected.length,
        selected.some((message) => message.viewOnce),
        hasDeleted,
      )
    ) {
      onError(
        t(
          selected.some((message) => message.viewOnce)
            ? 'chat.viewOnceForwardError'
            : hasDeleted
              ? 'chat.deletedForwardError'
              : 'chat.forwardLimitError',
        ),
      );
      return;
    }
    try {
      await chatRepository.forward(
        conversationId,
        selection.selectedIds,
        selection.selectedTargets,
      );
      selection.clear();
    } catch {
      onError(t('chat.sendError'));
    }
  }

  return (
    <>
      <input
        aria-label={t('chat.searchConversations')}
        placeholder={t('chat.searchConversations')}
        className="min-h-10 bg-surface-high p-2"
        type="search"
        value={search}
        onChange={(event) => setSearch(event.currentTarget.value)}
      />
      {query.data?.pages
        .flatMap((page) => page.items)
        .map((item: Conversation) => (
          <label key={item.id} className="flex items-center gap-1">
            <input
              type="checkbox"
              checked={selection.selectedTargets.includes(item.id)}
              onChange={(event) => {
                const checked = event.currentTarget.checked;
                selection.setTargets((current) =>
                  checked
                    ? [...new Set([...current, item.id])]
                    : current.filter((target) => target !== item.id),
                );
              }}
            />
            {item.otherUser.displayName} {item.product?.title ?? item.orderInfo?.productTitle}
          </label>
        ))}
      {query.hasNextPage ? (
        <button
          className="underline"
          type="button"
          disabled={query.isFetchingNextPage}
          onClick={() => void query.fetchNextPage().catch(() => onError(t('chat.loadError')))}
        >
          {t('common.loadMore')}
        </button>
      ) : null}
      <button
        className="ui-button ui-secondary"
        type="button"
        disabled={!selection.selectedTargets.length}
        onClick={() => void forward()}
      >
        {t('chat.forward')}
      </button>
    </>
  );
}
