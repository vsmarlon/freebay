import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { FcmService } from '../fcm.service';
import { NotificationsGateway } from '../notifications.gateway';
import { NotificationService } from './notification.service';
import { Prisma } from '@prisma/client';

describe('NotificationService payload contract', () => {
  let module: TestingModule;
  let service: NotificationService;
  const createNotification = jest.fn(
    async (args: { data: { type: string; data: Record<string, string> } }) => ({
      id: 'notification-id',
      payload: args.data.data,
      type: args.data.type,
    }),
  );
  const sendNotification = jest.fn(
    async (
      _userId: string,
      _title: string,
      _body: string,
      _data?: Record<string, string>,
    ) => undefined,
  );
  const sendSocketNotification = jest.fn();
  const persistedNotification = { id: 'notification-id', type: 'MENTION' as const };

  beforeEach(async () => {
    createNotification.mockClear();
    sendNotification.mockClear();
    sendSocketNotification.mockClear();
    createNotification.mockImplementation(async (args) => ({ id: persistedNotification.id, payload: args.data.data, type: args.data.type }));
    module = await Test.createTestingModule({
      providers: [
        NotificationService,
        {
          provide: PrismaService,
          useValue: { notification: { create: createNotification } },
        },
        { provide: FcmService, useValue: { sendNotification } },
        { provide: NotificationsGateway, useValue: { sendNotification: sendSocketNotification } },
      ],
    }).compile();
    service = module.get(NotificationService);
  });

  afterEach(async () => module.close());

  it('persists and pushes typed destination identifiers for notifications', async () => {
    await service.notifyMention('recipient', 'Mentioned in a post', 'post-id');
    await service.notifyMention(
      'recipient',
      'Mentioned in a comment',
      'post-id',
      'comment-id',
    );
    await service.notifyNewFollower('recipient', 'Follower', 'follower-id');
    await service.notifyDispute(
      'recipient',
      'dispute-id',
      'order-id',
      'Dispute updated',
    );

    const persistedPayloads = createNotification.mock.calls.map(
      ([args]) => args.data.data,
    );
    const pushedPayloads = sendNotification.mock.calls.map(([, , , data]) => data);

    expect(persistedPayloads).toEqual([
      { type: 'MENTION', action: 'post', postId: 'post-id' },
      {
        type: 'MENTION',
        action: 'post',
        postId: 'post-id',
        commentId: 'comment-id',
      },
      { type: 'FOLLOW', action: 'profile', userId: 'follower-id' },
      {
        type: 'DISPUTE',
        action: 'disputes',
        disputeId: 'dispute-id',
        orderId: 'order-id',
      },
    ]);
    expect(pushedPayloads).toEqual(persistedPayloads);
  });

  it('emits only an opaque invalidation after persistence and before FCM', async () => {
    await service.create({ userId: 'recipient', type: 'MENTION', title: 'private title', body: 'private body' });

    expect(sendSocketNotification).toHaveBeenCalledWith('recipient', { id: 'notification-id', type: 'MENTION' });
    expect(createNotification.mock.invocationCallOrder[0]).toBeLessThan(sendSocketNotification.mock.invocationCallOrder[0]);
    expect(sendSocketNotification.mock.invocationCallOrder[0]).toBeLessThan(sendNotification.mock.invocationCallOrder[0]);
  });

  it('does not emit when a duplicate notification is not persisted', async () => {
    createNotification.mockRejectedValueOnce(new Prisma.PrismaClientKnownRequestError('duplicate', { code: 'P2002', clientVersion: 'test' }));

    await expect(service.create({ id: 'duplicate', userId: 'recipient', type: 'MESSAGE', title: 'x', body: 'y' })).resolves.toBeNull();

    expect(sendSocketNotification).not.toHaveBeenCalled();
  });

  it('does not emit when persistence fails', async () => {
    createNotification.mockRejectedValueOnce(new Error('database unavailable'));

    await expect(service.create({ userId: 'recipient', type: 'MENTION', title: 'x', body: 'y' })).rejects.toThrow('database unavailable');

    expect(sendSocketNotification).not.toHaveBeenCalled();
  });

  it('emits after persistence even when FCM fails', async () => {
    sendNotification.mockRejectedValueOnce(new Error('FCM unavailable'));

    await expect(service.create({ userId: 'recipient', type: 'MENTION', title: 'x', body: 'y' })).rejects.toThrow('FCM unavailable');

    expect(sendSocketNotification).toHaveBeenCalledWith('recipient', { id: 'notification-id', type: 'MENTION' });
  });

  it('keeps FCM delivery independent when socket emission throws', async () => {
    sendSocketNotification.mockImplementationOnce(() => { throw new Error('socket unavailable'); });

    await expect(service.create({ userId: 'recipient', type: 'MENTION', title: 'x', body: 'y' })).resolves.toMatchObject({ id: 'notification-id' });

    expect(sendNotification).toHaveBeenCalledTimes(1);
  });

  it('persists and emits muted messages without calling FCM', async () => {
    await service.notifyNewMessage('recipient', 'Sender', 'conversation-id', 'message-id', { suppressPush: true });

    expect(createNotification).toHaveBeenCalledWith({ data: {
      id: 'message-id',
      userId: 'recipient',
      type: 'MESSAGE',
      title: 'Nova mensagem',
      body: 'Sender enviou uma mensagem',
      data: { type: 'MESSAGE', action: 'chat', conversationId: 'conversation-id', messageId: 'message-id' },
    } });
    expect(sendSocketNotification).toHaveBeenCalledWith('recipient', { id: 'notification-id', type: 'MESSAGE' });
    expect(sendNotification).not.toHaveBeenCalled();
  });

  it('preserves normal persistence, socket, and FCM behavior when unmuted', async () => {
    await service.notifyNewMessage('recipient', 'Sender', 'conversation-id', 'message-id', { suppressPush: false });

    expect(createNotification).toHaveBeenCalledTimes(1);
    expect(sendSocketNotification).toHaveBeenCalledWith('recipient', { id: 'notification-id', type: 'MESSAGE' });
    expect(sendNotification).toHaveBeenCalledWith('recipient', 'Nova mensagem', 'Sender enviou uma mensagem', {
      type: 'MESSAGE', action: 'chat', conversationId: 'conversation-id', messageId: 'message-id',
    });
  });

  it('does not call FCM for duplicate notifications or persistence errors', async () => {
    createNotification.mockRejectedValueOnce(new Prisma.PrismaClientKnownRequestError('duplicate', { code: 'P2002', clientVersion: 'test' }));
    await expect(service.notifyNewMessage('recipient', 'Sender', 'conversation-id', 'duplicate-id', { suppressPush: true })).resolves.toBeUndefined();
    expect(sendNotification).not.toHaveBeenCalled();
    expect(sendSocketNotification).not.toHaveBeenCalled();

    createNotification.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(service.notifyNewMessage('recipient', 'Sender', 'conversation-id', 'failed-id', { suppressPush: true })).rejects.toThrow('database unavailable');
    expect(sendNotification).not.toHaveBeenCalled();
    expect(sendSocketNotification).not.toHaveBeenCalled();
  });
});
