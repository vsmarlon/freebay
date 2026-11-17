import { act, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../../../tests/render-with-providers';
import { useChatSocket } from './use-chat-socket';

type Listener = (...args: unknown[]) => void;

type FakeSocket = {
  listeners: Map<string, Listener[]>;
  emitted: Array<{ event: string; payload: unknown; ack?: (response: unknown) => void }>;
  disconnects: number;
  on: (event: string, listener: Listener) => FakeSocket;
  emit: (event: string, payload?: unknown, ack?: (response: unknown) => void) => FakeSocket;
  connect: () => void;
  disconnect: () => void;
  removeAllListeners: () => void;
  fire: (event: string, ...args: unknown[]) => void;
  count: (event: string) => number;
  ack: (event: string) => ((response: unknown) => void) | undefined;
};

const fake = vi.hoisted(() => {
  const sockets: FakeSocket[] = [];
  const createChatSocket = () => {
    const socket: FakeSocket = {
      listeners: new Map(),
      emitted: [],
      disconnects: 0,
      on: (event, listener) => {
        socket.listeners.set(event, [...(socket.listeners.get(event) ?? []), listener]);
        return socket;
      },
      emit: (event, payload, ack) => {
        socket.emitted.push({ event, payload, ack });
        return socket;
      },
      connect: () => {},
      disconnect: () => {
        socket.disconnects += 1;
      },
      removeAllListeners: () => socket.listeners.clear(),
      fire: (event, ...args) => {
        for (const listener of socket.listeners.get(event) ?? []) listener(...args);
      },
      count: (event) => socket.listeners.get(event)?.length ?? 0,
      ack: (event) => [...socket.emitted].reverse().find((entry) => entry.event === event)?.ack,
    };
    sockets.push(socket);
    return socket;
  };
  return { sockets, createChatSocket };
});

vi.mock('../socket', () => ({ createChatSocket: fake.createChatSocket }));

function Harness({
  id,
  userId,
  otherUserId,
}: {
  id: string;
  userId: string;
  otherUserId?: string;
}) {
  const socket = useChatSocket(id, otherUserId, userId);
  return (
    <p>{`offline=${socket.offline} typing=${socket.typing} online=${socket.online} join=${socket.joinError}`}</p>
  );
}

const socket = () => fake.sockets[0];

describe('useChatSocket lifecycle', () => {
  beforeEach(() => {
    fake.sockets.length = 0;
  });

  it('keeps one connection when the counterpart id arrives with the transcript', () => {
    const { rerenderUi } = renderWithProviders(<Harness id="c1" userId="me" />);
    expect(fake.sockets).toHaveLength(1);
    act(() => socket().fire('connect'));

    rerenderUi(<Harness id="c1" userId="me" otherUserId="other" />);

    expect(fake.sockets).toHaveLength(1);
    expect(socket().disconnects).toBe(0);
    expect(socket().count('user_typing')).toBe(1);
  });

  it('applies presence and typing events for the resolved counterpart only', () => {
    const { rerenderUi } = renderWithProviders(<Harness id="c1" userId="me" />);
    rerenderUi(<Harness id="c1" userId="me" otherUserId="other" />);

    act(() => socket().fire('user_typing', { userId: 'other' }));
    act(() => socket().fire('user_online', { userId: 'other' }));
    expect(screen.getByText(/typing=true online=true/)).toBeInTheDocument();

    act(() => socket().fire('user_offline', { userId: 'stranger' }));
    expect(screen.getByText(/online=true/)).toBeInTheDocument();
  });

  it('re-joins and refetches the transcript on every (re)connect', () => {
    const { client } = renderWithProviders(<Harness id="c1" userId="me" otherUserId="other" />);
    const invalidate = vi.spyOn(client, 'invalidateQueries');

    act(() => socket().fire('connect'));
    act(() => socket().fire('connect'));

    expect(socket().emitted.filter((entry) => entry.event === 'join_conversation')).toHaveLength(2);
    expect(invalidate).toHaveBeenCalledTimes(2);
    expect(fake.sockets).toHaveLength(1);
  });

  it('clears a join refusal once a reconnect is accepted', () => {
    renderWithProviders(<Harness id="c1" userId="me" otherUserId="other" />);

    act(() => socket().fire('connect'));
    act(() => socket().ack('join_conversation')?.({ error: 'Not a participant' }));
    expect(screen.getByText(/join=Not a participant/)).toBeInTheDocument();

    act(() => socket().fire('connect'));
    act(() => socket().ack('join_conversation')?.({ event: 'joined', data: {} }));
    expect(screen.getByText(/join=\s*$/)).toBeInTheDocument();
  });

  it('leaves the room and drops every listener on unmount', () => {
    const { unmount } = renderWithProviders(<Harness id="c1" userId="me" otherUserId="other" />);
    unmount();

    expect(socket().emitted.some((entry) => entry.event === 'leave_conversation')).toBe(true);
    expect(socket().disconnects).toBe(1);
    expect(socket().count('new_message')).toBe(0);
    expect(socket().count('user_typing')).toBe(0);
  });
});
