import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Report, ReportReason, ReportTargetType } from '@prisma/client';
import { CreateReportInput } from '../dtos/report.dto';

@Injectable()
export class CreateReportUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: CreateReportInput): Promise<Either<AppError, Report>> {
    switch (input.targetType) {
      case 'USER': return this.reportUser(input);
      case 'POST': return this.reportPost(input);
      case 'CONVERSATION': return this.reportConversation(input);
      case 'MESSAGE': return this.reportMessage(input);
      case 'ORDER_CHAT': return this.reportOrderChat(input);
      case 'CHAT_MESSAGE': return this.reportChatMessage(input);
      default: return left(new BadRequestError('Invalid target type'));
    }
  }

  private async reportUser(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const userExists = await this.prisma.user.findUnique({ where: { id: input.targetId } });
    if (!userExists) {
      return left(new NotFoundError('User'));
    }

    const existingReport = await this.prisma.report.findUnique({
      where: { reporterId_reportedUserId: { reporterId: input.reporterId, reportedUserId: input.targetId } },
    });

    if (existingReport) {
      return left(new BadRequestError('You have already reported this user'));
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId: input.reporterId,
        reportedUserId: input.targetId,
        targetType: 'USER' as ReportTargetType,
        reason: input.reason as ReportReason,
        description: input.description,
      },
    });

    return right(report);
  }

  private async reportPost(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const postExists = await this.prisma.post.findUnique({ where: { id: input.targetId } });
    if (!postExists) {
      return left(new NotFoundError('Post'));
    }

    const existingReport = await this.prisma.report.findUnique({
      where: { reporterId_reportedPostId: { reporterId: input.reporterId, reportedPostId: input.targetId } },
    });

    if (existingReport) {
      return left(new BadRequestError('You have already reported this post'));
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId: input.reporterId,
        reportedPostId: input.targetId,
        targetType: 'POST' as ReportTargetType,
        reason: input.reason as ReportReason,
        description: input.description,
      },
    });

    return right(report);
  }

  private async reportConversation(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: input.targetId },
    });

    if (!conversation) {
      return left(new NotFoundError('Conversation'));
    }

    const isParticipant = conversation.user1Id === input.reporterId || conversation.user2Id === input.reporterId;
    if (!isParticipant) {
      return left(new BadRequestError('You are not a participant of this conversation'));
    }

    const existingReport = await this.prisma.report.findUnique({
      where: { reporterId_reportedDirectConversationId: { reporterId: input.reporterId, reportedDirectConversationId: input.targetId } },
    });

    if (existingReport) {
      return left(new BadRequestError('You have already reported this conversation'));
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId: input.reporterId,
        reportedDirectConversationId: input.targetId,
        targetType: 'CONVERSATION' as ReportTargetType,
        reason: input.reason as ReportReason,
        description: input.description,
      },
    });

    return right(report);
  }

  private async reportMessage(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const message = await this.prisma.directMessage.findUnique({
      where: { id: input.targetId },
      include: { conversation: true },
    });

    if (!message) {
      return left(new NotFoundError('Message'));
    }

    const conv = message.conversation;
    const isParticipant = conv.user1Id === input.reporterId || conv.user2Id === input.reporterId;
    if (!isParticipant) {
      return left(new BadRequestError('You are not a participant of this conversation'));
    }

    const existingReport = await this.prisma.report.findUnique({
      where: { reporterId_reportedDirectMessageId: { reporterId: input.reporterId, reportedDirectMessageId: input.targetId } },
    });

    if (existingReport) {
      return left(new BadRequestError('You have already reported this message'));
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId: input.reporterId,
        reportedDirectMessageId: input.targetId,
        targetType: 'MESSAGE' as ReportTargetType,
        reason: input.reason as ReportReason,
        description: input.description,
      },
    });

    return right(report);
  }

  private async reportOrderChat(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const order = await this.prisma.order.findUnique({
      where: { id: input.targetId },
    });

    if (!order) {
      return left(new NotFoundError('Order'));
    }

    const isParticipant = order.buyerId === input.reporterId || order.sellerId === input.reporterId;
    if (!isParticipant) {
      return left(new BadRequestError('You are not a participant of this order chat'));
    }

    const existingReport = await this.prisma.report.findUnique({
      where: { reporterId_reportedOrderChatId: { reporterId: input.reporterId, reportedOrderChatId: input.targetId } },
    });

    if (existingReport) {
      return left(new BadRequestError('You have already reported this order chat'));
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId: input.reporterId,
        reportedOrderChatId: input.targetId,
        targetType: 'ORDER_CHAT' as ReportTargetType,
        reason: input.reason as ReportReason,
        description: input.description,
      },
    });

    return right(report);
  }

  private async reportChatMessage(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const message = await this.prisma.chatMessage.findUnique({
      where: { id: input.targetId },
      include: { order: true },
    });

    if (!message) {
      return left(new NotFoundError('Chat message'));
    }

    const order = message.order;
    const isParticipant = order.buyerId === input.reporterId || order.sellerId === input.reporterId;
    if (!isParticipant) {
      return left(new BadRequestError('You are not a participant of this order chat'));
    }

    const existingReport = await this.prisma.report.findUnique({
      where: { reporterId_reportedChatMessageId: { reporterId: input.reporterId, reportedChatMessageId: input.targetId } },
    });

    if (existingReport) {
      return left(new BadRequestError('You have already reported this message'));
    }

    const report = await this.prisma.report.create({
      data: {
        reporterId: input.reporterId,
        reportedChatMessageId: input.targetId,
        targetType: 'CHAT_MESSAGE' as ReportTargetType,
        reason: input.reason as ReportReason,
        description: input.description,
      },
    });

    return right(report);
  }
}
