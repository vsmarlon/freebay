import { Link } from 'react-router';
import { Dialog, Icon, Select } from '../../../components';
import { useI18n } from '../../../core/locale';
import { pathsFor } from '../../../core/routes';
import { chatCatalogs } from '../catalogs';
import { CHAT_THEMES, type Transcript } from '../model';

export function ConversationDetailsDialog({
  page,
  muted,
  presenceHidden,
  background,
  onClose,
  onToggleMute,
  onTogglePresence,
  onOpenGallery,
  onOpenStarred,
  onBlock,
  onReport,
  onTheme,
  onBackgroundChange,
  onBackgroundUpload,
  onBackgroundSave,
}: {
  page: Transcript | undefined;
  muted: boolean;
  presenceHidden: boolean;
  background: string;
  onClose: () => void;
  onToggleMute: () => void;
  onTogglePresence: () => void;
  onOpenGallery: () => void;
  onOpenStarred: () => void;
  onBlock: () => void;
  onReport: () => void;
  onTheme: (theme: string) => void;
  onBackgroundChange: (value: string) => void;
  onBackgroundUpload: (file: File) => void;
  onBackgroundSave: () => void;
}) {
  const { t, path } = useI18n(chatCatalogs);
  return (
    <Dialog open onClose={onClose} title={t('chat.details')}>
      <div className="mb-4 mt-3 flex flex-wrap gap-2">
        {page?.otherUserId ? (
          <Link
            className="icon-control"
            to={path(pathsFor.person(page.otherUserId))}
            aria-label={`${t('chat.profile')}: ${page.otherUser.displayName}`}
            title={`${t('chat.profile')}: ${page.otherUser.displayName}`}
          >
            <Icon name="user" size={18} />
          </Link>
        ) : null}
        <button className="icon-control" type="button" aria-pressed={muted} onClick={onToggleMute}>
          <Icon name={muted ? 'volumeOn' : 'volumeOff'} size={18} />
          <span className="sr-only">{muted ? t('chat.unmute') : t('chat.mute')}</span>
        </button>
        <button
          className="icon-control"
          type="button"
          aria-pressed={presenceHidden}
          onClick={onTogglePresence}
        >
          <Icon name={presenceHidden ? 'eye' : 'eyeOff'} size={18} />
          <span className="sr-only">
            {presenceHidden ? t('chat.showPresence') : t('chat.hidePresence')}
          </span>
        </button>
        <button
          className="icon-control"
          type="button"
          onClick={onOpenGallery}
          aria-label={t('chat.media')}
          title={t('chat.media')}
        >
          <Icon name="image" size={18} />
        </button>
        <button
          className="icon-control"
          type="button"
          onClick={onOpenStarred}
          aria-label={t('chat.starred')}
          title={t('chat.starred')}
        >
          <Icon name="bookmark" size={18} />
        </button>
        {page?.otherUserId ? (
          <button
            className="icon-control icon-control-danger"
            type="button"
            onClick={onBlock}
            aria-label={t('chat.block')}
            title={t('chat.block')}
          >
            <Icon name="shield" size={18} />
          </button>
        ) : null}
        {page?.otherUserId ? (
          <button
            className="icon-control"
            type="button"
            onClick={onReport}
            aria-label={t('chat.report')}
            title={t('chat.report')}
          >
            <Icon name="doc" size={18} />
          </button>
        ) : null}
      </div>
      <Select
        label={t('chat.theme')}
        value={page?.preference?.theme ?? 'DEFAULT'}
        onChange={(event) => onTheme(event.currentTarget.value)}
      >
        {CHAT_THEMES.map((theme) => (
          <option key={theme} value={theme}>
            {t(`chat.theme.${theme}`)}
          </option>
        ))}
      </Select>
      <div className="mb-[2px] mt-[14px] flex items-center gap-2">
        <label
          className="icon-control cursor-pointer"
          aria-label={t('chat.uploadBackground')}
          title={t('chat.uploadBackground')}
        >
          <Icon name="image" size={18} />
          <input
            className="sr-only"
            type="file"
            accept="image/png,image/jpeg,image/webp,image/gif"
            aria-label={t('chat.uploadBackground')}
            onChange={(event) => {
              const file = event.currentTarget.files?.[0];
              if (file) onBackgroundUpload(file);
              event.currentTarget.value = '';
            }}
          />
        </label>
        <input
          aria-label={t('chat.background')}
          className="min-w-0 flex-1 bg-surface-high p-2"
          value={background}
          onChange={(event) => onBackgroundChange(event.currentTarget.value)}
        />
        <button className="icon-control" type="button" onClick={onBackgroundSave}>
          <Icon name="check" size={18} />
          <span className="sr-only">{t('chat.saveBackground')}</span>
        </button>
      </div>
    </Dialog>
  );
}
