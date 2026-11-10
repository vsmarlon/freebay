import { useCallback, useState } from 'react';
import { Dialog } from '../../../components';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';

export function VideoAttachmentDialog({
  file,
  initialViewOnce,
  pending,
  onClose,
  onSend,
}: {
  file: File;
  initialViewOnce: boolean;
  pending: boolean;
  onClose: () => void;
  onSend: (file: File, caption: string, viewOnce: boolean) => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const [caption, setCaption] = useState('');
  const [viewOnce, setViewOnce] = useState(initialViewOnce);
  const previewRef = useCallback(
    (node: HTMLVideoElement | null) => {
      if (!node) return;
      const url = URL.createObjectURL(file);
      node.src = url;
      return () => URL.revokeObjectURL(url);
    },
    [file],
  );
  return (
    <Dialog open onClose={onClose} title={t('chat.videoPreview')}>
      <video ref={previewRef} className="max-h-96 max-w-full" controls muted playsInline />
      <label className="ui-field mt-3">
        {t('chat.caption')}
        <textarea
          className="min-h-20"
          maxLength={5000}
          value={caption}
          onChange={(event) => setCaption(event.currentTarget.value)}
        />
      </label>
      <label className="mt-2 flex items-center gap-2">
        <input
          type="checkbox"
          checked={viewOnce}
          onChange={(event) => setViewOnce(event.currentTarget.checked)}
        />
        {t('chat.viewOnce')}
      </label>
      <button
        className="ui-button ui-primary mt-3"
        type="button"
        disabled={pending}
        onClick={() => onSend(file, caption, viewOnce)}
      >
        {t('chat.send')}
      </button>
    </Dialog>
  );
}
