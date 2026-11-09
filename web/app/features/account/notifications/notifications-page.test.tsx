import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../../../tests/render-with-providers';
import NotificationsPage from './notifications-page';
import { notificationsApi, type NotificationsPage as Page } from './notifications.api';

vi.mock('./notifications.api');
vi.mock('./use-notifications-socket', () => ({ useNotificationsSocket: () => {} }));

let currentUser: { id: string } | null = { id: 'account-a' };

vi.mock('../../../core/session', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../../../core/session')>();
  return {
    ...actual,
    RequireAuth: ({ children }: { children: React.ReactNode }) => children,
    useSession: () => ({
      user: currentUser,
      isPending: false,
      isSigningOut: false,
      signOutFailed: false,
      error: null,
      reload: async () => {},
      signOut: async () => {},
    }),
  };
});

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((done) => {
    resolve = done;
  });
  return { promise, resolve };
}

const notice = (id: string, title: string) => ({
  id,
  title,
  read: false,
  createdAt: '2026-11-09T12:00:00.000Z',
});

const page = (items: ReturnType<typeof notice>[]): Page => ({
  items,
  nextCursor: null,
  hasMore: false,
});

beforeEach(() => {
  vi.clearAllMocks();
  currentUser = { id: 'account-a' };
  vi.mocked(notificationsApi.unreadCount).mockResolvedValue(1);
});

describe('NotificationsPage', () => {
  it('marks every notification read', async () => {
    vi.mocked(notificationsApi.list).mockResolvedValue(page([notice('n1', 'First notice')]));
    vi.mocked(notificationsApi.readAll).mockResolvedValue(undefined);

    renderWithProviders(<NotificationsPage />, '/notifications');

    expect(await screen.findByText('First notice')).toBeInTheDocument();
    const [markAll] = screen.getAllByRole('button', { name: 'Marcar tudo como lido' });
    await userEvent.click(markAll);

    expect(notificationsApi.readAll).toHaveBeenCalledTimes(1);
  });

  it('ignores a late response from the previous account after switching users', async () => {
    const pendingA = deferred<Page>();
    vi.mocked(notificationsApi.list).mockImplementation(async () =>
      currentUser?.id === 'account-a' ? pendingA.promise : page([notice('n2', 'B notice')]),
    );

    const view = renderWithProviders(<NotificationsPage />, '/notifications');
    await waitFor(() => expect(notificationsApi.list).toHaveBeenCalledTimes(1));
    currentUser = { id: 'account-b' };
    view.rerenderUi(<NotificationsPage />);

    expect(await screen.findByText('B notice')).toBeInTheDocument();

    pendingA.resolve(page([notice('n1', 'A notice')]));
    await waitFor(() => expect(notificationsApi.list).toHaveBeenCalledTimes(2));
    expect(screen.queryByText('A notice')).not.toBeInTheDocument();
  });
});
