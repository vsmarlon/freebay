import { createServer, type Server as HttpServer } from 'node:http';
import { Server as SocketServer, type ServerOptions } from 'socket.io';
import { GATEWAY_OPTIONS } from '@nestjs/websockets/constants';
import { NotificationsGateway } from './notifications.gateway';

function hasOriginOptions(value: unknown): value is Pick<ServerOptions, 'allowRequest' | 'cors'> {
  if (typeof value !== 'object' || value === null) return false;
  const validAllowRequest = !('allowRequest' in value) || typeof value.allowRequest === 'function';
  const cors = 'cors' in value ? value.cors : undefined;
  return validAllowRequest && (cors === undefined || (typeof cors === 'object' && cors !== null));
}

describe('NotificationsGateway origin handshake', () => {
  let httpServer: HttpServer | undefined;
  let io: SocketServer | undefined;

  afterEach(async () => {
    if (io) await new Promise<void>((resolve) => io?.close(() => resolve()));
    else if (httpServer?.listening) await new Promise<void>((resolve, reject) => httpServer?.close((error) => error ? reject(error) : resolve()));
    io = undefined;
    httpServer = undefined;
  });

  it('rejects unlisted browser origins while allowing origin-less native clients', async () => {
    const configured: unknown = Reflect.getMetadata(GATEWAY_OPTIONS, NotificationsGateway);
    const options = hasOriginOptions(configured) ? configured : {};
    httpServer = createServer();
    io = new SocketServer(httpServer, { allowRequest: options.allowRequest, cors: options.cors });
    await new Promise<void>((resolve, reject) => {
      httpServer?.once('error', reject);
      httpServer?.listen(0, '127.0.0.1', resolve);
    });
    const address = httpServer.address();
    if (!address || typeof address === 'string') throw new Error('Test server failed to bind');
    const url = `http://127.0.0.1:${address.port}/socket.io/?EIO=4&transport=polling`;

    const denied = await fetch(url, { headers: { Origin: 'https://attacker.example' } });
    expect(denied.status).toBe(403);
    await denied.body?.cancel();

    const native = await fetch(url);
    expect(native.status).toBe(200);
    await native.body?.cancel();
  });
});
