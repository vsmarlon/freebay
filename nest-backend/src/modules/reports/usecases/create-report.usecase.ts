import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { Report, ReportTargetType } from '@prisma/client';
import { CreateReportInput } from '../dtos/report.dto';
import { ReportDatabaseRepository } from '../data/repositories/report-database.repository';

@Injectable()
export class CreateReportUseCase {
  constructor(private readonly reportRepository: ReportDatabaseRepository) {}

  async execute(input: CreateReportInput): Promise<Either<AppError, Report>> {
    switch (input.targetType) {
      case ReportTargetType.USER: return this.reportUser(input);
      case ReportTargetType.POST: return this.reportPost(input);
      case ReportTargetType.CONVERSATION: return this.reportConversation(input);
      case ReportTargetType.MESSAGE: return this.reportMessage(input);
      case ReportTargetType.ORDER_CHAT: return this.reportOrderChat(input);
      case ReportTargetType.CHAT_MESSAGE: return this.reportChatMessage(input);
      default: return left(new BadRequestError('Invalid target type'));
    }
  }

  private async reportUser(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const userResult = await this.reportRepository.findUserById(input.targetId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) return left(new NotFoundError('User'));

    const existingResult = await this.reportRepository.findReportByUnique({
      reporterId_reportedUserId: { reporterId: input.reporterId, reportedUserId: input.targetId },
    });
    if (existingResult.isLeft()) return left(existingResult.value);
    if (existingResult.value) return left(new BadRequestError('You have already reported this user'));

    const createResult = await this.reportRepository.createReport({
      reporterId: input.reporterId,
      reportedUserId: input.targetId,
      targetType: ReportTargetType.USER,
      reason: input.reason,
      description: input.description,
    });
    if (createResult.isLeft()) return left(createResult.value);
    return right(createResult.value);
  }

  private async reportPost(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const postResult = await this.reportRepository.findPostById(input.targetId);
    if (postResult.isLeft()) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));

    const existingResult = await this.reportRepository.findReportByUnique({
      reporterId_reportedPostId: { reporterId: input.reporterId, reportedPostId: input.targetId },
    });
    if (existingResult.isLeft()) return left(existingResult.value);
    if (existingResult.value) return left(new BadRequestError('You have already reported this post'));

    const createResult = await this.reportRepository.createReport({
      reporterId: input.reporterId,
      reportedPostId: input.targetId,
      targetType: ReportTargetType.POST,
      reason: input.reason,
      description: input.description,
    });
    if (createResult.isLeft()) return left(createResult.value);
    return right(createResult.value);
  }

  private async reportConversation(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const conversationResult = await this.reportRepository.findConversationById(input.targetId);
    if (conversationResult.isLeft()) return left(conversationResult.value);
    if (!conversationResult.value) return left(new NotFoundError('Conversation'));

    const isParticipant = conversationResult.value.user1Id === input.reporterId || conversationResult.value.user2Id === input.reporterId;
    if (!isParticipant) return left(new BadRequestError('You are not a participant of this conversation'));

    const existingResult = await this.reportRepository.findReportByUnique({
      reporterId_reportedDirectConversationId: { reporterId: input.reporterId, reportedDirectConversationId: input.targetId },
    });
    if (existingResult.isLeft()) return left(existingResult.value);
    if (existingResult.value) return left(new BadRequestError('You have already reported this conversation'));

    const createResult = await this.reportRepository.createReport({
      reporterId: input.reporterId,
      reportedDirectConversationId: input.targetId,
      targetType: ReportTargetType.CONVERSATION,
      reason: input.reason,
      description: input.description,
    });
    if (createResult.isLeft()) return left(createResult.value);
    return right(createResult.value);
  }

  private async reportMessage(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const messageResult = await this.reportRepository.findDirectMessageById(input.targetId);
    if (messageResult.isLeft()) return left(messageResult.value);
    if (!messageResult.value) return left(new NotFoundError('Message'));

    const conv = messageResult.value.conversation;
    const isParticipant = conv.user1Id === input.reporterId || conv.user2Id === input.reporterId;
    if (!isParticipant) return left(new BadRequestError('You are not a participant of this conversation'));

    const existingResult = await this.reportRepository.findReportByUnique({
      reporterId_reportedDirectMessageId: { reporterId: input.reporterId, reportedDirectMessageId: input.targetId },
    });
    if (existingResult.isLeft()) return left(existingResult.value);
    if (existingResult.value) return left(new BadRequestError('You have already reported this message'));

    const createResult = await this.reportRepository.createReport({
      reporterId: input.reporterId,
      reportedDirectMessageId: input.targetId,
      targetType: ReportTargetType.MESSAGE,
      reason: input.reason,
      description: input.description,
    });
    if (createResult.isLeft()) return left(createResult.value);
    return right(createResult.value);
  }

  private async reportOrderChat(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const orderResult = await this.reportRepository.findOrderById(input.targetId);
    if (orderResult.isLeft()) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const isParticipant = orderResult.value.buyerId === input.reporterId || orderResult.value.sellerId === input.reporterId;
    if (!isParticipant) return left(new BadRequestError('You are not a participant of this order chat'));

    const existingResult = await this.reportRepository.findReportByUnique({
      reporterId_reportedOrderChatId: { reporterId: input.reporterId, reportedOrderChatId: input.targetId },
    });
    if (existingResult.isLeft()) return left(existingResult.value);
    if (existingResult.value) return left(new BadRequestError('You have already reported this order chat'));

    const createResult = await this.reportRepository.createReport({
      reporterId: input.reporterId,
      reportedOrderChatId: input.targetId,
      targetType: ReportTargetType.ORDER_CHAT,
      reason: input.reason,
      description: input.description,
    });
    if (createResult.isLeft()) return left(createResult.value);
    return right(createResult.value);
  }

  private async reportChatMessage(input: CreateReportInput): Promise<Either<AppError, Report>> {
    const messageResult = await this.reportRepository.findChatMessageById(input.targetId);
    if (messageResult.isLeft()) return left(messageResult.value);
    if (!messageResult.value) return left(new NotFoundError('Chat message'));

    const order = messageResult.value.order;
    const isParticipant = order.buyerId === input.reporterId || order.sellerId === input.reporterId;
    if (!isParticipant) return left(new BadRequestError('You are not a participant of this order chat'));

    const existingResult = await this.reportRepository.findReportByUnique({
      reporterId_reportedChatMessageId: { reporterId: input.reporterId, reportedChatMessageId: input.targetId },
    });
    if (existingResult.isLeft()) return left(existingResult.value);
    if (existingResult.value) return left(new BadRequestError('You have already reported this message'));

    const createResult = await this.reportRepository.createReport({
      reporterId: input.reporterId,
      reportedChatMessageId: input.targetId,
      targetType: ReportTargetType.CHAT_MESSAGE,
      reason: input.reason,
      description: input.description,
    });
    if (createResult.isLeft()) return left(createResult.value);
    return right(createResult.value);
  }
}
