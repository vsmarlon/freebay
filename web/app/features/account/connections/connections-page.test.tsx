import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../../../tests/render-with-providers';
import type { User } from '../account';
import ConnectionsPage from './connections-page';
import { connectionsApi } from '../api';

vi.mock('../api');
// The route shell gates on the session; this page's own behavior is what is under test.
vi.mock('../../../core/session', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../../../core/session')>();
  return {
    ...actual,
    RequireAuth: ({ children }: { children: React.ReactNode }) => children,
    useSession: () => ({
      user: null,
      isPending: false,
      isSigningOut: false,
      signOutFailed: false,
      error: null,
      reload: async () => {},
      signOut: async () => {},
    }),
  };
});

function usersFixture(count: number, startAt = 0): User[] {
  return Array.from({ length: count }, (_, index) => ({
    id: `user-${startAt + index}`,
    displayName: `Person ${startAt + index}`,
    username: `person${startAt + index}`,
    avatarUrl: null,
  }));
}

describe('ConnectionsPage', () => {
  it('lists followers and loads the next page on demand', async () => {
    vi.mocked(connectionsApi.list)
      .mockResolvedValueOnce(usersFixture(20))
      .mockResolvedValueOnce(usersFixture(3, 20));
    vi.mocked(connectionsApi.followStates).mockResolvedValue({});

    renderWithProviders(<ConnectionsPage />, '/profile/followers');

    expect(await screen.findByRole('link', { name: 'Person 0 @person0' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Person 19 @person19' })).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: 'Carregar mais' }));

    expect(await screen.findByRole('link', { name: 'Person 22 @person22' })).toBeInTheDocument();
    expect(connectionsApi.list).toHaveBeenLastCalledWith(
      '/users/me/followers',
      20,
      expect.anything(),
    );
  });

  it('shows a retry notice when the first page fails', async () => {
    vi.mocked(connectionsApi.list).mockRejectedValue(new Error('boom'));

    renderWithProviders(<ConnectionsPage />, '/profile/followers');

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Não foi possível carregar estas informações.',
    );
  });
});
