import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../tests/render-with-providers';
import { clearAccessToken } from './api';
import { SessionProvider, useSession } from './session';

const alice = {
  id: 'user-a',
  displayName: 'Alice',
  username: 'alice',
  avatarUrl: null,
  role: 'USER' as const,
};
const bob = {
  id: 'user-b',
  displayName: 'Bob',
  username: 'bob',
  avatarUrl: null,
  role: 'USER' as const,
};

function Probe() {
  const { user, reload, signOut } = useSession();
  return (
    <div>
      <p>{user?.displayName ?? 'signed-out'}</p>
      <button type="button" onClick={() => void reload()}>
        reload
      </button>
      <button type="button" onClick={() => void signOut().catch(() => {})}>
        sign out
      </button>
    </div>
  );
}

const json = (data: unknown, status = 200) => new Response(JSON.stringify({ data }), { status });

beforeEach(() => {
  clearAccessToken();
});

afterEach(() => {
  vi.unstubAllGlobals();
  clearAccessToken();
});

describe('session provider', () => {
  it('drops the previous account caches when the tab signs in as someone else', async () => {
    let current = alice;
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: RequestInfo | URL) => {
        const url = String(input);
        if (url === '/auth/web/session/access-token') return json({ token: 'access-token' });
        if (url === '/users/me') return json(current);
        throw new Error(`unexpected request ${url}`);
      }),
    );
    const { client } = renderWithProviders(
      <SessionProvider>
        <Probe />
      </SessionProvider>,
    );
    expect(await screen.findByText('Alice')).toBeInTheDocument();
    client.setQueryData(['account', 'me'], { email: 'alice@example.com' });

    current = bob;
    await userEvent.click(screen.getByRole('button', { name: 'reload' }));

    expect(await screen.findByText('Bob')).toBeInTheDocument();
    await waitFor(() => expect(client.getQueryData(['account', 'me'])).toBeUndefined());
    expect(client.getQueryData(['session', 'user'])).toMatchObject({ id: 'user-b' });
  });

  it('renews the cookies and retries when logout is refused for an expired access cookie', async () => {
    const calls: string[] = [];
    let logoutRefused = true;
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
        const url = String(input);
        calls.push(`${init?.method ?? 'GET'} ${url}`);
        if (url === '/auth/web/session/access-token') return json({ token: 'access-token' });
        if (url === '/auth/web/session/refresh') return json({ refreshed: true });
        if (url === '/auth/web/session/logout' && logoutRefused) {
          logoutRefused = false;
          return new Response(JSON.stringify({ message: 'expired' }), { status: 401 });
        }
        if (url === '/auth/web/session/logout') return new Response(null, { status: 204 });
        if (url === '/users/me') return json(alice);
        throw new Error(`unexpected request ${url}`);
      }),
    );
    renderWithProviders(
      <SessionProvider>
        <Probe />
      </SessionProvider>,
    );
    expect(await screen.findByText('Alice')).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: 'sign out' }));

    await waitFor(() =>
      expect(calls.filter((call) => call.endsWith('/auth/web/session/logout'))).toHaveLength(2),
    );
    expect(calls).toContain('POST /auth/web/session/refresh');
  });

  it('keeps the signed-in account cached when logout fails for a real error', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
        const url = String(input);
        if (url === '/auth/web/session/access-token') return json({ token: 'access-token' });
        if (url === '/auth/web/session/logout' && init?.method === 'POST')
          return new Response(JSON.stringify({ message: 'boom' }), { status: 500 });
        if (url === '/users/me') return json(alice);
        throw new Error(`unexpected request ${url}`);
      }),
    );
    const { client } = renderWithProviders(
      <SessionProvider>
        <Probe />
      </SessionProvider>,
    );
    expect(await screen.findByText('Alice')).toBeInTheDocument();
    client.setQueryData(['account', 'me'], { email: 'alice@example.com' });

    await userEvent.click(screen.getByRole('button', { name: 'sign out' }));

    expect(await screen.findByText('Alice')).toBeInTheDocument();
    expect(client.getQueryData(['account', 'me'])).toEqual({ email: 'alice@example.com' });
  });
});
