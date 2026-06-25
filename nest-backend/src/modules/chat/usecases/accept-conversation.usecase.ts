import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { AcceptConversationOutput } from '../dtos/chat.dto';

@Injectable()
export class AcceptConversationUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(conversationId: string, userId: string): Promise<Either<AppError, AcceptConversationOutput>> {
    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return left(new NotFoundError('Conversation'));
    }

    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      return left(new BadRequestError('Not authorized'));
    }

    if (conversation.status !== 'PENDING') {
      return left(new BadRequestError('Conversation is not pending'));
    }

    await this.prisma.directConversation.update({
      where: { id: conversationId },
      data: { status: 'ACTIVE' },
    });

    return right({ accepted: true });
  }
}
