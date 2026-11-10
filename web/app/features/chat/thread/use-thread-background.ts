import { useState } from 'react';
import { useI18n } from '../../../core/locale';
import { useMediaUrl } from '../../../core/media';
import { chatCatalogs } from '../catalogs';
import { chatRepository } from '../repository';

const DATA_IMAGE = /^data:image\/(?:png|jpeg|webp|gif);base64,[A-Za-z0-9+/=]+$/;

export function useThreadBackground(conversationId: string, saved: string | null | undefined) {
  const { t } = useI18n(chatCatalogs);
  const [override, setOverride] = useState<string | null>(null);
  const [error, setError] = useState('');
  const value = override ?? saved ?? '';
  const isDataUrl = DATA_IMAGE.test(value) && Boolean(value);
  const media = useMediaUrl(!isDataUrl && value.startsWith('/media/background/') ? value : null);

  async function upload(file: File) {
    if (!file.type.startsWith('image/')) return;
    try {
      const { url } = await chatRepository.upload(file, 'background');
      await chatRepository.background(conversationId, url);
      setOverride(url);
    } catch {
      setError(t('chat.sendError'));
    }
  }

  async function save() {
    if (!value.startsWith('/media/background/') && !DATA_IMAGE.test(value)) {
      setError(t('chat.mediaError'));
      return;
    }
    try {
      await chatRepository.background(conversationId, value);
    } catch {
      setError(t('chat.sendError'));
    }
  }

  return {
    value,
    image: isDataUrl ? value : (media.url ?? null),
    error: error || (media.error ? t('chat.mediaError') : ''),
    setValue: setOverride,
    upload,
    save,
  };
}

export type ThreadBackground = ReturnType<typeof useThreadBackground>;
