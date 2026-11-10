import { useCallback, useEffect, useRef, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { chatRepository } from '../repository';
import { shouldRefreshReadState, deletedCopy, type ChatMessage } from '../model';
import { createChatSocket, type ChatSocket } from '../socket';
import { chatKeys, patchThreadMessage, patchThreadMessages } from '../queries';

// One socket per Thread mount: the keyed <Thread> remounts per conversation, so
// every hook argument is a constant for the mount lifetime and the handlers can
// close over them safely.
export function useChatSocket(
  id: string,
  otherUserId: string | undefined,
  userId: string | undefined,
) {
  const client = useQueryClient();
  const [offline, setOffline] = useState(false);
  const [typing, setTyping] = useState(false);
  const [online, setOnline] = useState(false);
  const [joinError, setJoinError] = useState('');
  const socketRef = useRef<ChatSocket | null>(null);
  const typingTimer = useRef<number | null>(null);

  useEffect(() => {
    if (!id || !userId) return;
    const socket = createChatSocket();
    socketRef.current = socket;
    socket.on('connect', () => {
      setOffline(false);
      socket.emit(
        'join_conversation',
        { conversationId: id },
        (response: { error?: string } | undefined) => {
          if (response?.error) setJoinError(response.error);
        },
      );
      // Canonical read-refresh and catch-up: server truth lands through the invalidation.
      void client.invalidateQueries({ queryKey: chatKeys.thread(id) });
    });
    socket.on('disconnect', () => {
      setOffline(true);
      setTyping(false);
      setOnline(false);
    });
    socket.on('connect_error', () => setOffline(true));
    socket.on('new_message', (message: ChatMessage) => {
      if (message.conversationId !== id) return;
      patchThreadMessages(client, id, [message]);
      // Read receipt is best-effort; the next canonical refresh reconciles gaps.
      if (message.senderId !== userId) void chatRepository.markRead(id).catch(() => {});
    });
    socket.on('messages_read', (event: { conversationId: string; readerId: string }) => {
      if (shouldRefreshReadState(event, id, userId))
        void client.invalidateQueries({ queryKey: chatKeys.thread(id) });
    });
    socket.on('message_deleted', ({ messageId }: { messageId: string }) =>
      patchThreadMessage(client, id, messageId, deletedCopy),
    );
    socket.on(
      'reaction_updated',
      ({
        messageId,
        reactions,
      }: {
        messageId: string;
        reactions: NonNullable<ChatMessage['reactions']>;
      }) => patchThreadMessage(client, id, messageId, (message) => ({ ...message, reactions })),
    );
    socket.on('user_typing', ({ userId: senderId }: { userId: string }) => {
      if (senderId === otherUserId) setTyping(true);
    });
    socket.on('user_stopped_typing', ({ userId: senderId }: { userId: string }) => {
      if (senderId === otherUserId) setTyping(false);
    });
    socket.on('user_online', ({ userId: senderId }: { userId: string }) => {
      if (senderId === otherUserId) setOnline(true);
    });
    socket.on('user_offline', ({ userId: senderId }: { userId: string }) => {
      if (senderId === otherUserId) setOnline(false);
    });
    socket.connect();
    return () => {
      if (typingTimer.current !== null) {
        window.clearTimeout(typingTimer.current);
        typingTimer.current = null;
      }
      socket.emit('typing_stop', { conversationId: id });
      socket.emit('leave_conversation', { conversationId: id });
      socket.removeAllListeners();
      socket.disconnect();
      if (socketRef.current === socket) socketRef.current = null;
    };
  }, [id, otherUserId, userId, client]);

  const emitDraftActivity = useCallback(
    (value: string) => {
      socketRef.current?.emit(value ? 'typing' : 'typing_stop', { conversationId: id });
      if (typingTimer.current !== null) window.clearTimeout(typingTimer.current);
      if (value)
        typingTimer.current = window.setTimeout(
          () => socketRef.current?.emit('typing_stop', { conversationId: id }),
          1500,
        );
    },
    [id],
  );

  const emitStopTyping = useCallback(() => {
    socketRef.current?.emit('typing_stop', { conversationId: id });
  }, [id]);

  return { offline, typing, online, joinError, emitDraftActivity, emitStopTyping };
}
