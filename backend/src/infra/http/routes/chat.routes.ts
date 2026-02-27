import { FastifyInstance } from 'fastify';
import { authGuard } from '@/presentation/middlewares/auth-guard';
import { prisma } from '@/infra/database/prisma/client';
import { apiSuccess, apiError } from '@/presentation/response';

export async function chatRoutes(app: FastifyInstance) {
  // GET /chat — list chats for the authenticated user (grouped by order)
  app.get('/', { preHandler: [authGuard] }, async (request, reply) => {
    const userId = request.user.userId;

    const orders = await prisma.order.findMany({
      where: {
        OR: [{ buyerId: userId }, { sellerId: userId }],
      },
      include: {
        buyer: { select: { id: true, displayName: true, avatarUrl: true } },
        seller: { select: { id: true, displayName: true, avatarUrl: true } },
        chatMessages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    const chats = orders
      .filter((order) => order.chatMessages.length > 0)
      .map((order) => {
        const otherUser = order.buyerId === userId ? order.seller : order.buyer;
        const lastMsg = order.chatMessages[0];

        return {
          id: order.id,
          oderId: order.id,
          oderName: otherUser.displayName,
          oderAvatarUrl: otherUser.avatarUrl,
          lastMessage: lastMsg.content,
          timestamp: lastMsg.createdAt.toISOString(),
          unread: lastMsg.senderId !== userId && lastMsg.readAt === null,
          status: 'active',
        };
      });

    return reply.send(apiSuccess(chats));
  });

  // GET /chat/:chatId — get messages for a specific order/chat
  app.get<{ Params: { chatId: string } }>(
    '/:chatId',
    { preHandler: [authGuard] },
    async (request, reply) => {
      const userId = request.user.userId;
      const { chatId } = request.params;

      const order = await prisma.order.findFirst({
        where: {
          id: chatId,
          OR: [{ buyerId: userId }, { sellerId: userId }],
        },
        include: {
          buyer: { select: { id: true, displayName: true, avatarUrl: true } },
          seller: { select: { id: true, displayName: true, avatarUrl: true } },
          chatMessages: {
            orderBy: { createdAt: 'asc' },
          },
        },
      });

      if (!order) {
        return reply.code(404).send(apiError('NOT_FOUND', 'Conversa não encontrada'));
      }

      const otherUser = order.buyerId === userId ? order.seller : order.buyer;

      return reply.send(
        apiSuccess({
          id: order.id,
          oderId: order.id,
          oderName: otherUser.displayName,
          oderAvatarUrl: otherUser.avatarUrl,
          messages: order.chatMessages,
          status: 'active',
        }),
      );
    },
  );

  // POST /chat/:chatId/messages — send a message
  app.post<{ Params: { chatId: string }; Body: { message: string } }>(
    '/:chatId/messages',
    { preHandler: [authGuard] },
    async (request, reply) => {
      const userId = request.user.userId;
      const { chatId } = request.params;
      const { message } = request.body;

      const order = await prisma.order.findFirst({
        where: {
          id: chatId,
          OR: [{ buyerId: userId }, { sellerId: userId }],
        },
      });

      if (!order) {
        return reply.code(404).send(apiError('NOT_FOUND', 'Conversa não encontrada'));
      }

      const chatMessage = await prisma.chatMessage.create({
        data: {
          orderId: chatId,
          senderId: request.user.userId!,
          content: message,
        },
      });

      return reply.code(201).send(apiSuccess(chatMessage));
    },
  );

  // PATCH /chat/:chatId/read — mark messages as read
  app.patch<{ Params: { chatId: string } }>(
    '/:chatId/read',
    { preHandler: [authGuard] },
    async (request, reply) => {
      const userId = request.user.userId;
      const { chatId } = request.params;

      await prisma.chatMessage.updateMany({
        where: {
          orderId: chatId,
          senderId: { not: userId },
          readAt: null,
        },
        data: {
          readAt: new Date(),
        },
      });

      return reply.send(apiSuccess({ marked: true }));
    },
  );
}
