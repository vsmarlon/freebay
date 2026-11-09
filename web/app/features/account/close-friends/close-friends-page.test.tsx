import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../../../tests/render-with-providers';
import type { User } from '../account';
import CloseFriendsPage from './close-friends-page';
import { closeFriendsApi } from './close-friends.api';

vi.mock('./close-friends.api');
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

const friend: User = {
  id: 'user-1',
  displayName: 'Close Friend',
  username: 'friend',
  avatarUrl: null,
};
const candidate: User = {
  id: 'user-2',
  displayName: 'New Candidate',
  username: 'candidate',
  avatarUrl: null,
};

describe('CloseFriendsPage', () => {
  it('adds a candidate to the close-friends list', async () => {
    vi.mocked(closeFriendsApi.selected).mockResolvedValue([friend]);
    vi.mocked(closeFriendsApi.candidates).mockResolvedValue([friend, candidate]);
    vi.mocked(closeFriendsApi.add).mockResolvedValue(undefined);

    renderWithProviders(<CloseFriendsPage />, '/settings/close-friends');

    expect(
      await screen.findByRole('link', { name: 'New Candidate @candidate' }),
    ).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Salvar alterações' }));

    expect(closeFriendsApi.add).toHaveBeenCalledWith('user-2');
  });
});
