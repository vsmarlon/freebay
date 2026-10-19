import { io, type Socket } from 'socket.io-client';
import { session } from '../../core/session';

export type ChatSocket = Socket;

export function createChatSocket(): ChatSocket {
  const origin = import.meta.env.VITE_SOCKET_URL || window.location.origin;
  const socket = io(`${origin}/chat`, {
    path: '/socket.io',
    transports: ['websocket', 'polling'],
    autoConnect: false,
    reconnection: true,
    reconnectionAttempts: 8,
    auth: (callback) => {
      void session.socketToken().then((token) => callback({ token })).catch(() => callback({ token: '' }));
    },
  });
  let refreshed = false;
  socket.on('connect_error', (error) => {
    if (refreshed || !/unauthorized|jwt/i.test(error.message)) return;
    refreshed = true;
    void session.refresh().then(() => {
      refreshed = false;
      socket.connect();
    }).catch(() => socket.disconnect());
  });
  socket.on('connect', () => { refreshed = false; });
  return socket;
}
