import { Dialog } from '../../../components';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';
import { useStarredMessages } from '../queries';

export function StarredMessagesDialog({
  conversationId,
  onClose,
}: {
  conversationId: string;
  onClose: () => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const query = useStarredMessages(conversationId, true);
  return (
    <Dialog open onClose={onClose} title={t('chat.starred')}>
      {query.isError ? <p role="alert">{t('chat.loadError')}</p> : null}
      {query.data?.length ? (
        query.data.map((message) => (
          <p key={message.id} className="my-2 bg-surface-mid p-3">
            {message.content ?? t('chat.media')}
          </p>
        ))
      ) : (
        <p>{t('chat.starredEmpty')}</p>
      )}
    </Dialog>
  );
}
