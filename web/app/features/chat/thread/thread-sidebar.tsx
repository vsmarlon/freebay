import { Link } from 'react-router';
import { Avatar } from '../../../components';
import { useI18n } from '../../../core/locale';
import { pathsFor } from '../../../core/routes';
import { chatCatalogs } from '../catalogs';
import type { Conversation } from '../model';

export function ThreadSidebar({
  conversations,
  activeId,
}: {
  conversations: Conversation[];
  activeId: string;
}) {
  const { t, path } = useI18n(chatCatalogs);
  return (
    <aside
      className="hidden min-h-0 min-w-0 overflow-x-hidden overflow-y-auto surface p-3 md:block"
      aria-labelledby="chat-list-title"
    >
      <h2 id="chat-list-title" className="mb-3 font-display text-xl font-bold">
        {t('chat.title')}
      </h2>
      <nav aria-label={t('chat.title')}>
        <ul className="grid min-w-0 gap-1">
          {conversations.map((item) => (
            <li key={`${item.threadType}:${item.id}`} className="min-w-0">
              <Link
                aria-current={item.id === activeId ? 'page' : undefined}
                className={`flex min-w-0 items-center gap-2 p-3 ${item.id === activeId ? 'bg-surface-high' : 'hover:bg-surface-mid'}`}
                to={path(pathsFor.conversation(item.id))}
                title={`${item.otherUser.displayName} — ${item.product?.title ?? item.orderInfo?.productTitle ?? item.lastMessage?.content ?? item.status}`}
              >
                <span className="flex-none">
                  <Avatar
                    src={item.otherUser.avatarUrl}
                    name={item.otherUser.displayName}
                    size={36}
                  />
                </span>
                <span className="min-w-0 flex-1 overflow-hidden">
                  <span className="block whitespace-nowrap font-semibold">
                    {item.otherUser.displayName}
                  </span>
                  <span className="block whitespace-nowrap text-xs text-muted">
                    {item.product?.title ??
                      item.orderInfo?.productTitle ??
                      item.lastMessage?.content ??
                      item.status}
                  </span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      </nav>
    </aside>
  );
}
