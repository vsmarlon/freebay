import { Dialog } from '../../../components';
import { useI18n } from '../../../core/locale';
import { AuthenticatedMedia } from '../media';
import { chatCatalogs } from '../catalogs';
import { type ChatMessage, type MediaKind } from '../model';
import { threadMessages, useMediaMessages } from '../queries';

const isMediaType = (
  type: string,
): type is Extract<ChatMessage['type'], 'IMAGE' | 'VIDEO' | 'AUDIO'> =>
  type === 'IMAGE' || type === 'VIDEO' || type === 'AUDIO';

export function MediaGalleryDialog({
  conversationId,
  kind,
  onKindChange,
  onClose,
  onError,
}: {
  conversationId: string;
  kind: MediaKind;
  onKindChange: (kind: MediaKind) => void;
  onClose: () => void;
  onError: (message: string) => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const query = useMediaMessages(conversationId, kind);
  const items = query.data ? threadMessages(query.data.pages) : [];
  return (
    <Dialog open onClose={onClose} title={t('chat.media')}>
      <nav className="my-3 flex flex-wrap gap-2">
        {(['IMAGE', 'VIDEO', 'AUDIO'] as const).map((type) => (
          <button key={type} className="ui-button ui-secondary" onClick={() => onKindChange(type)}>
            {t(`chat.media${type === 'IMAGE' ? 'Image' : type === 'VIDEO' ? 'Video' : 'Audio'}`)}
          </button>
        ))}
      </nav>
      {query.isError ? <p role="alert">{t('chat.loadError')}</p> : null}
      <div className="grid max-h-[65svh] gap-3 overflow-auto">
        {items.map((message) =>
          message.attachmentUrl && isMediaType(message.type) ? (
            <AuthenticatedMedia
              key={message.id}
              src={message.attachmentUrl}
              type={
                message.type === 'VIDEO' ? 'video' : message.type === 'AUDIO' ? 'audio' : 'image'
              }
              alt={t('chat.media')}
            />
          ) : null,
        )}
      </div>
      {query.hasNextPage ? (
        <button
          className="ui-button ui-secondary mt-3"
          disabled={query.isFetchingNextPage}
          onClick={() => void query.fetchNextPage().catch(() => onError(t('chat.loadError')))}
        >
          {t('common.loadMore')}
        </button>
      ) : null}
    </Dialog>
  );
}
