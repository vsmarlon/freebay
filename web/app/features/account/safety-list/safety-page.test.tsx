import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../../../tests/render-with-providers';
import type { User } from '../account';
import SafetyListPage from './safety-page';
import { safetyApi } from './safety.api';

vi.mock('./safety.api');
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

const blocked: User = {
  id: 'user-1',
  displayName: 'Blocked Person',
  username: 'blocked',
  avatarUrl: null,
};

describe('SafetyListPage', () => {
  it('unblocks a person from the blocked list', async () => {
    vi.mocked(safetyApi.list).mockResolvedValue([blocked]);
    vi.mocked(safetyApi.remove).mockResolvedValue(undefined);

    renderWithProviders(<SafetyListPage />, '/settings/blocked');

    expect(
      await screen.findByRole('link', { name: 'Blocked Person @blocked' }),
    ).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Remover' }));

    expect(safetyApi.remove).toHaveBeenCalledWith(false, 'user-1');
  });

  it('shows the empty state when the list has nobody', async () => {
    vi.mocked(safetyApi.list).mockResolvedValue([]);

    renderWithProviders(<SafetyListPage />, '/settings/restricted');

    expect(await screen.findByText('Nada por aqui ainda.')).toBeInTheDocument();
  });
});
