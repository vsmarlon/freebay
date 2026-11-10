import { useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Link, useNavigate } from 'react-router';
import { useSession } from '../../../core/session';
import { Frame, Panel, useAccountText } from '../account';
import { notificationDestination } from '../notification-destination';
import type { Notice } from './notifications.api';
import {
  notificationsKeys,
  useNotifications,
  useReadAllNotifications,
  useReadNotification,
  useUnreadCount,
} from './notifications.queries';
import { useNotificationsSocket } from './use-notifications-socket';

export default function NotificationsPage() {
  const { t, path, locale } = useAccountText();
  const navigate = useNavigate();
  const { user } = useSession();
  const userId = user?.id;
  const client = useQueryClient();

  const notifications = useNotifications(userId);
  const unread = useUnreadCount(userId);
  const read = useReadNotification(userId);
  const readAll = useReadAllNotifications(userId);

  const refresh = useCallback(() => {
    void client.invalidateQueries({ queryKey: notificationsKeys.list(userId) });
    void client.invalidateQueries({ queryKey: notificationsKeys.unread(userId) });
  }, [client, userId]);
  useNotificationsSocket(userId, refresh);

  const items = notifications.data?.pages.flatMap((page) => page.items) ?? [];

  async function open(item: Notice): Promise<boolean> {
    if (item.read) return true;
    try {
      await read.mutateAsync(item.id);
      return true;
    } catch {
      return false;
    }
  }

  // Destinations are intentionally mapped only from validated identifiers, never notification-provided URLs.
  return (
    <Frame title={t('notifications')}>
      <Panel>
        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
          <p aria-live="polite">{t('unreadCount', { count: unread.data ?? '—' })}</p>
          <button
            disabled={readAll.isPending || read.isPending}
            className="min-h-11 bg-surface-high px-4"
            onClick={() => readAll.mutate()}
          >
            {readAll.isPending ? t('loading') : t('unread')}
          </button>
        </div>
        {unread.isError ? (
          <p role="alert" className="text-danger">
            {t('unreadCountError')}{' '}
            <button className="underline" onClick={() => void unread.refetch()}>
              {t('retry')}
            </button>
          </p>
        ) : null}
        {notifications.isError || readAll.isError ? (
          <p role="alert" className="text-danger">
            {t('error')} <button onClick={() => void notifications.refetch()}>{t('retry')}</button>
          </p>
        ) : null}
        {!items.length && !notifications.isError && !notifications.isPending ? (
          <p>{t('emptyNotifications')}</p>
        ) : null}
        <div className="grid gap-2">
          {items.map((item) => {
            const route = notificationDestination({
              ...(item.data && typeof item.data === 'object' ? item.data : {}),
              type: item.type,
            });
            const busy = read.isPending && read.variables === item.id;
            return (
              <article
                key={item.id}
                className={`bg-surface-mid p-4 ${item.read ? '' : 'border-l-4 border-brand'}`}
              >
                <h2 className="font-semibold">
                  {item.title ?? item.content ?? t('notifications')}
                </h2>
                {item.body ? <p>{item.body}</p> : null}
                <time className="text-sm text-secondary" dateTime={item.createdAt}>
                  {new Date(item.createdAt).toLocaleString(locale)}
                </time>
                {route ? (
                  <Link
                    onClick={(event) => {
                      event.preventDefault();
                      void open(item).then((ok) => {
                        if (ok) navigate(path(route));
                      });
                    }}
                    aria-disabled={busy}
                    className="ml-3 underline"
                    to={path(route)}
                  >
                    {t('open')}
                  </Link>
                ) : (
                  <button
                    disabled={busy}
                    className="ml-3 underline"
                    onClick={() => void open(item)}
                  >
                    {item.read ? t('read') : t('unread')}
                  </button>
                )}
              </article>
            );
          })}
        </div>
        {notifications.hasNextPage ? (
          <button
            className="mt-4 min-h-11 bg-surface-high px-4"
            disabled={notifications.isFetchingNextPage}
            onClick={() => void notifications.fetchNextPage()}
          >
            {t('loadMore')}
          </button>
        ) : null}
      </Panel>
    </Frame>
  );
}
