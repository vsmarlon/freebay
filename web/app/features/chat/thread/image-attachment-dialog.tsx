import { useState } from 'react';
import { Dialog } from '../../../components';
import { ImageEditor } from '../../../components/image-editor';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';

export function ImageAttachmentDialog({
  file,
  pending,
  onClose,
  onSend,
}: {
  file: File;
  pending: boolean;
  onClose: () => void;
  onSend: (file: File, caption: string) => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const [editedFile, setEditedFile] = useState<File | null>(null);
  const [caption, setCaption] = useState('');
  return (
    <Dialog open onClose={onClose} title={t('chat.editImage')}>
      {!editedFile ? (
        <ImageEditor file={file} onCancel={onClose} onSave={setEditedFile} />
      ) : (
        <>
          <label className="ui-field">
            {t('chat.caption')}
            <textarea
              className="min-h-20"
              maxLength={5000}
              value={caption}
              onChange={(event) => setCaption(event.currentTarget.value)}
            />
          </label>
          <button
            type="button"
            className="ui-button ui-primary mt-3"
            disabled={pending}
            onClick={() => onSend(editedFile, caption)}
          >
            {t('chat.send')}
          </button>
        </>
      )}
    </Dialog>
  );
}
