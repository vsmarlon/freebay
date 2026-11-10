import { useEffect } from 'react';
import { io } from 'socket.io-client';
import { accessTokenForSocket } from '../../../core/api';

/** Subscribes to the notification socket and calls `onChange` on push and reconnect. */
export function useNotificationsSocket(userId: string | undefined, onChange: () => void) {
  useEffect(() => {
    if (!userId) return;
    const socket = io(`${location.origin}/notifications`, {
      auth: (callback) => {
        void accessTokenForSocket()
          .then((token) => callback({ token }))
          .catch(() => callback({ token: '' }));
      },
      transports: ['websocket'],
    });
    socket.on('notification', onChange);
    socket.on('connect', onChange);
    return () => {
      socket.disconnect();
    };
  }, [userId, onChange]);
}
