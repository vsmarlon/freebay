import { Link } from 'react-router';
import { Icon } from '../../../components';
import { useI18n } from '../../../core/locale';
import { pathsFor } from '../../../core/routes';
import { chatCatalogs } from '../catalogs';
import type { Conversation, Transcript } from '../model';

export function ThreadHeader({
  page,
  record,
  presence,
  actions,
}: {
  page: Transcript | undefined;
  record: Conversation | null;
  presence: {
    muted: boolean;
    hidden: boolean;
    online: boolean;
    typing: boolean;
    status: string | undefined;
  };
  actions: {
    openDetails: () => void;
    openGallery: () => void;
    openStarred: () => void;
    toggleArchive: () => void;
    deleteConversation: () => void;
  };
}) {
  const { t, path } = useI18n(chatCatalogs);
  const archiveLabel = page?.preference?.isArchived ? t('chat.unarchive') : t('chat.archive');
  return (
    <header className="flex shrink-0 flex-wrap items-center gap-2 surface p-3 sm:p-4">
      <Link
        className="icon-control"
        to={path('messages')}
        aria-label={t('common.back')}
        title={t('common.back')}
      >
        <Icon name="back" size={18} />
      </Link>
      <div className="min-w-0 flex-1 overflow-hidden">
        <h1 className="whitespace-nowrap font-display text-xl font-bold">
          {page?.otherUser.displayName ?? t('chat.thread')}
        </h1>
        <p className="text-xs text-muted">
          {presence.muted
            ? t('chat.muted')
            : presence.hidden
              ? t('chat.presenceHidden')
              : presence.online
                ? t('chat.online')
                : presence.typing
                  ? t('chat.typing')
                  : presence.status}
        </p>
        {record?.product ? (
          <Link
            className="text-xs text-brand underline"
            to={path(pathsFor.product(record.product.id))}
          >
            {record.product.title}
          </Link>
        ) : null}
        {record?.orderInfo ? (
          <Link
            className="text-xs text-brand underline"
            to={path(pathsFor.order(record.orderInfo.id))}
          >
            {record.orderInfo.productTitle}
          </Link>
        ) : null}
      </div>
      {[
        { icon: 'info' as const, label: t('chat.details'), action: actions.openDetails },
        { icon: 'image' as const, label: t('chat.media'), action: actions.openGallery },
        { icon: 'bookmark' as const, label: t('chat.starred'), action: actions.openStarred },
        { icon: 'archive' as const, label: archiveLabel, action: actions.toggleArchive },
        {
          icon: 'trash' as const,
          label: t('chat.deleteConversation'),
          action: actions.deleteConversation,
          danger: true,
        },
      ].map((action) => (
        <button
          key={action.label}
          className={`icon-control ${action.danger ? 'icon-control-danger' : ''}`}
          type="button"
          onClick={action.action}
          aria-label={action.label}
          title={action.label}
        >
          <Icon name={action.icon} size={18} />
        </button>
      ))}
    </header>
  );
}
