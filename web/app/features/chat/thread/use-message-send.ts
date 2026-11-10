import { useState, type RefObject } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';
import { mediaMessagePayload, type ChatMessage, type MediaKind } from '../model';
import { chatKeys, patchThreadMessages } from '../queries';
import { chatRepository } from '../repository';
import { useProductInquiryDraft } from '../hooks/use-product-inquiry-draft';

const uuid = () => crypto.randomUUID();
type SendPayload = Parameters<typeof chatRepository.send>[1];

export function useMessageSend({
  conversationId,
  inquiry,
  reply,
  onReplyChange,
  typing,
  onError,
  inputRef,
  onSendingChange,
}: {
  conversationId: string;
  inquiry: { ready: boolean; productId?: string; otherUserId?: string };
  reply: ChatMessage | null;
  onReplyChange: (message: ChatMessage | null) => void;
  typing: { emitDraftActivity: (value: string) => void; emitStopTyping: () => void };
  onError: (message: string) => void;
  inputRef: RefObject<HTMLTextAreaElement | null>;
  onSendingChange: (sending: boolean) => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const client = useQueryClient();
  const [draft, setDraft] = useState('');
  const [viewOnce, setViewOnce] = useState(false);
  const [draftEdited, setDraftEdited] = useState(false);
  const send = useMutation({
    mutationFn: (payload: SendPayload) => chatRepository.send(conversationId, payload),
    onMutate: () => onSendingChange(true),
    onSuccess: (saved) => {
      patchThreadMessages(client, conversationId, [saved]);
      void client.invalidateQueries({ queryKey: chatKeys.sidebar });
      setDraft('');
      onReplyChange(null);
      setViewOnce(false);
      typing.emitStopTyping();
      inputRef.current?.focus();
    },
    onError: () => onError(t('chat.sendError')),
    onSettled: () => onSendingChange(false),
  });

  useProductInquiryDraft({
    ready: inquiry.ready,
    productId: inquiry.productId,
    otherUserId: inquiry.otherUserId,
    draft,
    draftEdited,
    greeting: t('chat.productInquiryGreeting'),
    onDraft: setDraft,
  });

  function changeDraft(value: string) {
    setDraftEdited(true);
    setDraft(value);
    typing.emitDraftActivity(value);
  }

  function sendDraft() {
    const content = draft.trim();
    if (!content || send.isPending) return;
    onError('');
    send.mutate({
      content,
      type: 'TEXT',
      clientMessageId: uuid(),
      ...(reply ? { replyToId: reply.id } : {}),
    });
  }

  async function upload(
    file: File,
    durationMs?: number,
    caption?: string,
    viewOnceOverride = viewOnce,
  ) {
    onError('');
    try {
      const { url } = await chatRepository.upload(file);
      const type: MediaKind = file.type.startsWith('image/')
        ? 'IMAGE'
        : file.type.startsWith('video/')
          ? 'VIDEO'
          : 'AUDIO';
      await send.mutateAsync({
        ...mediaMessagePayload({
          type,
          attachmentUrl: url,
          viewOnce: viewOnceOverride,
          durationMs,
        }),
        clientMessageId: uuid(),
        ...(caption?.trim() ? { content: caption.trim() } : {}),
        ...(reply ? { replyToId: reply.id } : {}),
      });
    } catch {
      onError(t('chat.sendError'));
    }
  }

  return {
    draft,
    viewOnce,
    pending: send.isPending,
    changeDraft,
    sendDraft,
    setViewOnce,
    upload,
    sendAsync: send.mutateAsync,
  };
}

export type MessageSender = ReturnType<typeof useMessageSend>;
