import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useQueryClient } from '@tanstack/react-query';
import { useI18n } from '../../../core/locale';
import { useToast } from '../../../components/toast';
import { chatCatalogs } from '../catalogs';
import type { ChatMessage, Transcript } from '../model';
import {
  patchConversationRecord,
  patchThreadMessage,
  threadPreferenceUpdate,
  updateThreadPreference,
} from '../queries';
import { chatRepository } from '../repository';

export function useThreadActions({
  conversationId,
  page,
}: {
  conversationId: string;
  page: Transcript | undefined;
}) {
  const { t, path } = useI18n(chatCatalogs);
  const { show: showToast } = useToast();
  const navigate = useNavigate();
  const client = useQueryClient();
  const [error, setError] = useState('');
  const muted = page?.preference?.muted ?? false;

  async function toggleMute() {
    const next = !muted;
    try {
      await chatRepository.mute(conversationId, next);
      updateThreadPreference(client, conversationId, threadPreferenceUpdate({ muted: next }));
    } catch {
      setError(t('chat.sendError'));
    }
  }

  async function toggleReaction(message: ChatMessage, emoji: string) {
    try {
      const result = await chatRepository.react(conversationId, message.id, emoji);
      patchThreadMessage(client, conversationId, message.id, (item) => ({
        ...item,
        reactions: result.reactions,
      }));
    } catch {
      setError(t('chat.sendError'));
    }
  }

  async function openExternal(url: string) {
    try {
      const parsed = new URL(url);
      if (!['https:', 'http:'].includes(parsed.protocol)) throw new Error('unsupported');
      const result = await chatRepository.verifyUrl(parsed.href);
      if (!result.isSafe || !window.confirm(`${t('chat.openLink')}?\n${result.normalizedUrl}`)) {
        setError(t('chat.unsafeLink'));
        return;
      }
      window.open(result.normalizedUrl, '_blank', 'noopener,noreferrer');
    } catch {
      setError(t('chat.unsafeLink'));
    }
  }

  async function applyArchive(isArchived: boolean) {
    await chatRepository.archive(conversationId, isArchived);
    updateThreadPreference(client, conversationId, threadPreferenceUpdate({ isArchived }));
  }

  async function toggleArchive() {
    const next = !(page?.preference?.isArchived ?? false);
    try {
      await applyArchive(next);
      showToast({
        message: next ? t('chat.archivedNotice') : t('chat.unarchivedNotice'),
        actionLabel: t('common.undo'),
        onAction: () => {
          void applyArchive(!next).catch(() => showToast({ message: t('chat.sendError') }));
        },
      });
    } catch {
      setError(t('chat.sendError'));
    }
  }

  async function deleteConversation() {
    try {
      await chatRepository.deleteConversation(conversationId);
      await navigate(path('messages'));
    } catch {
      setError(t('chat.sendError'));
    }
  }

  async function blockCounterpart() {
    if (!page?.otherUserId) return;
    const targetId = page.otherUserId;
    try {
      await chatRepository.blockUser(targetId);
      await navigate(path('messages'));
      showToast({
        message: t('chat.blockedNotice'),
        actionLabel: t('common.undo'),
        onAction: () => {
          void chatRepository
            .unblockUser(targetId)
            .catch(() => showToast({ message: t('chat.sendError') }));
        },
      });
    } catch {
      setError(t('chat.sendError'));
    }
  }

  async function reportCounterpart() {
    if (!page?.otherUserId) return;
    try {
      await chatRepository.reportUser(page.otherUserId);
    } catch {
      setError(t('chat.sendError'));
    }
  }

  async function setTheme(theme: string) {
    try {
      await chatRepository.theme(conversationId, theme);
      updateThreadPreference(client, conversationId, threadPreferenceUpdate({ theme }));
    } catch {
      setError(t('chat.sendError'));
    }
  }

  async function acceptConversation() {
    try {
      await chatRepository.accept(conversationId);
      patchConversationRecord(client, conversationId, page?.otherUser.displayName, {
        status: 'ACCEPTED',
      });
    } catch {
      setError(t('chat.sendError'));
    }
  }

  return {
    error,
    muted,
    setError,
    toggleMute,
    toggleReaction,
    openExternal,
    toggleArchive,
    deleteConversation,
    blockCounterpart,
    reportCounterpart,
    setTheme,
    acceptConversation,
  };
}

export type ThreadActions = ReturnType<typeof useThreadActions>;
