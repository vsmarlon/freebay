import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { io, Socket as ClientSocket } from 'socket.io-client';
import { AppModule } from '../../src/app.module';
import { StripeProvider } from '../../src/modules/payments/providers/stripe-provider';
import { AllExceptionsFilter } from '../../src/shared/http/exception-filter';
import { TransformInterceptor } from '../../src/shared/http/transform.interceptor';
import { EitherInterceptor } from '../../src/shared/http/response.interceptor';
import { createValidationPipe } from '../../src/shared/http/validation-pipe.factory';
import { assertSafeTestEnvironment, cleanDatabase } from '../utils/test-helpers';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, allowExitOnIdle: true });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

describe('Chat socket privacy (real gateway and database)', () => {
  let app: INestApplication;
  let baseUrl: string;
  let conversationId: string;
  let seller: { id: string; token: string };
  let buyer: { id: string; token: string };
  let stranger: { id: string; token: string };
  const sockets: ClientSocket[] = [];
  const suffix = Date.now().toString(36);

  async function register(name: string): Promise<{ id: string; token: string }> {
    const response = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        displayName: `Socket ${name}`,
        username: `${name}_${suffix}`,
        email: `${name}-${suffix}@example.com`,
        password: 'password123',
      }),
    });
    expect(response.status).toBe(201);
    const json = await response.json() as { data: { user: { id: string }; token: string } };
    return { id: json.data.user.id, token: json.data.token };
  }

  async function connect(token: string): Promise<ClientSocket> {
    const socket = io(`${baseUrl}/chat`, { auth: { token }, transports: ['websocket'], forceNew: true, reconnection: false });
    sockets.push(socket);
    await new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('Socket connection timed out')), 3000);
      socket.once('connect', () => { clearTimeout(timeout); resolve(); });
      socket.once('connect_error', (error: Error) => { clearTimeout(timeout); reject(error); });
    });
    return socket;
  }

  async function join(socket: ClientSocket): Promise<void> {
    let acknowledgement: unknown;
    const joined = new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error(`Socket join timed out: ${JSON.stringify(acknowledgement)}`)), 3000);
      socket.once('joined', () => { clearTimeout(timeout); resolve(); });
    });
    socket.emit('join_conversation', { conversationId }, (reply: unknown) => { acknowledgement = reply; });
    await joined;
  }

  beforeAll(async () => {
    assertSafeTestEnvironment();
    await prisma.$connect();
    await cleanDatabase(prisma);
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(StripeProvider).useValue({}).compile();
    app = module.createNestApplication();
    app.useGlobalPipes(createValidationPipe());
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new TransformInterceptor(), new EitherInterceptor());
    await app.init();
    await app.listen(0);
    const address = app.getHttpServer().address();
    if (address === null || typeof address === 'string') throw new Error('No HTTP port');
    baseUrl = `http://127.0.0.1:${address.port}`;

    seller = await register('seller');
    buyer = await register('buyer');
    stranger = await register('stranger');
    const response = await fetch(`${baseUrl}/chat/conversations`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${seller.token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ targetUserId: buyer.id }),
    });
    expect(response.status).toBe(201);
    const json = await response.json() as { data: { conversationId: string } };
    conversationId = json.data.conversationId;
  }, 120000);

  afterEach(() => {
    for (const socket of sockets.splice(0)) socket.disconnect();
  });

  afterAll(async () => {
    await app?.close();
    await cleanDatabase(prisma);
    await prisma.$disconnect();
    await pool.end();
  });

  it('rejects an invalid token before reporting a connected socket', async () => {
    const socket = io(`${baseUrl}/chat`, { auth: { token: 'invalid' }, transports: ['websocket'], forceNew: true, reconnection: false });
    sockets.push(socket);
    const outcome = await new Promise<string>((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('Socket authentication timed out')), 3000);
      socket.once('connect', () => { clearTimeout(timeout); resolve('connect'); });
      socket.once('connect_error', () => { clearTimeout(timeout); resolve('connect_error'); });
    });
    expect(outcome).toBe('connect_error');
  });

  it('rejects typing from a nonparticipant but delivers it from a joined participant', async () => {
    const recipient = await connect(buyer.token);
    await join(recipient);
    const intruder = await connect(stranger.token);
    const received: unknown[] = [];
    recipient.on('user_typing', (payload) => received.push(payload));
    recipient.on('user_stopped_typing', (payload) => received.push(payload));

    intruder.emit('typing', { conversationId });
    intruder.emit('typing_stop', { conversationId });
    await new Promise((resolve) => setTimeout(resolve, 150));
    expect(received).toEqual([]);

    const author = await connect(seller.token);
    await join(author);
    author.emit('typing', { conversationId });
    await new Promise((resolve) => setTimeout(resolve, 150));
    expect(received).toEqual([{ userId: seller.id }]);
  });

  it('scopes presence to the conversation and waits for the last device to leave', async () => {
    const strangerSocket = await connect(stranger.token);
    const leaked: unknown[] = [];
    strangerSocket.on('user_online', (event) => leaked.push(event));
    strangerSocket.on('user_offline', (event) => leaked.push(event));

    const recipient = await connect(buyer.token);
    await join(recipient);
    const online: unknown[] = [];
    const offline: unknown[] = [];
    recipient.on('user_online', (event) => online.push(event));
    recipient.on('user_offline', (event) => offline.push(event));

    const first = await connect(seller.token);
    await join(first);
    const second = await connect(seller.token);
    await join(second);
    await new Promise((resolve) => setTimeout(resolve, 150));
    expect(leaked).toEqual([]);
    expect(online).toEqual([{ userId: seller.id, lastSeenAt: null }]);

    first.disconnect();
    await new Promise((resolve) => setTimeout(resolve, 150));
    expect(offline).toEqual([]);
    second.disconnect();
    await new Promise((resolve) => setTimeout(resolve, 150));
    expect(offline).toEqual([expect.objectContaining({ userId: seller.id })]);
  });
});
