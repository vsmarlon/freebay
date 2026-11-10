import { Icon } from '../../../components';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';
import { useAudioRecorder } from '../hooks/use-audio-recorder';
import type { MessageSender } from './use-message-send';

type Recorder = ReturnType<typeof useAudioRecorder>;

export function ComposerControls({
  sender,
  recorder,
  onImage,
  onVideo,
  onLocation,
  onProducts,
}: {
  sender: MessageSender;
  recorder: Recorder;
  onImage: (file: File) => void;
  onVideo: (file: File) => void;
  onLocation: () => void;
  onProducts: () => void;
}) {
  const { t } = useI18n(chatCatalogs);
  function selectAttachment(file: File) {
    if (file.type.startsWith('image/')) onImage(file);
    else if (file.type.startsWith('video/')) onVideo(file);
    else void sender.upload(file);
  }
  return (
    <>
      <div className="flex flex-wrap items-center gap-2 *:size-[38px] *:flex-none [&_.ui-icon-toggle]:border-(--edge) [&_.ui-icon-toggle]:bg-surface-mid">
        <label
          className="icon-control cursor-pointer"
          aria-label={t('chat.upload')}
          title={t('chat.upload')}
        >
          <Icon name="attach" size={18} />
          <input
            className="sr-only"
            type="file"
            accept="image/*,video/*,audio/*"
            disabled={sender.pending}
            aria-label={t('chat.upload')}
            onChange={(event) => {
              const file = event.currentTarget.files?.[0];
              if (file) selectAttachment(file);
              event.currentTarget.value = '';
            }}
          />
        </label>
        <label className="ui-icon-toggle" title={t('chat.viewOnce')}>
          <input
            type="checkbox"
            checked={sender.viewOnce}
            onChange={(event) => sender.setViewOnce(event.currentTarget.checked)}
            aria-label={t('chat.viewOnce')}
          />
          <Icon name="viewOnce" size={18} />
        </label>
        <button className="icon-control" type="button" onClick={onLocation}>
          <Icon name="pin" size={18} />
          <span className="sr-only">{t('chat.location')}</span>
        </button>
        <button className="icon-control" type="button" onClick={onProducts}>
          <Icon name="sell" size={18} />
          <span className="sr-only">{t('chat.shareProduct')}</span>
        </button>
        {!recorder.recording ? (
          <button className="icon-control" type="button" onClick={() => void recorder.start()}>
            <Icon name="mic" size={18} />
            <span className="sr-only">{t('chat.record')}</span>
          </button>
        ) : (
          <span className="recording-pill" style={{ width: 'auto', height: 'auto' }}>
            <span className="recording-dot" aria-hidden="true" />
            {t('chat.recording')} {recorder.elapsedSeconds}s
            <button className="icon-control" type="button" onClick={recorder.stop}>
              <Icon name="send" size={16} />
              <span className="sr-only">{t('chat.send')}</span>
            </button>
            <button
              className="icon-control icon-control-danger"
              type="button"
              onClick={recorder.cancel}
            >
              <Icon name="close" size={16} />
              <span className="sr-only">{t('chat.cancel')}</span>
            </button>
          </span>
        )}
        <button
          className="icon-control icon-control-primary ml-auto"
          type="submit"
          disabled={sender.pending || !sender.draft.trim()}
        >
          <Icon name="send" size={18} />
          <span className="sr-only">{t('chat.send')}</span>
        </button>
      </div>
      {recorder.unsupported ? (
        <p role="status" className="text-xs text-muted">
          {t('chat.recordUnsupported')}
        </p>
      ) : null}
      {recorder.failure ? (
        <p role="alert" className="text-xs text-danger">
          {recorder.failure === 'permission'
            ? t('chat.recordPermissionError')
            : t('chat.recordUnsupported')}
        </p>
      ) : null}
    </>
  );
}
