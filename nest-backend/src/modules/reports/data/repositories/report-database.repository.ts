import { Injectable } from '@nestjs/common';
import { Report, Prisma, User, Post, DirectConversation, Order } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { DirectMessageWithConversation, ChatMessageWithOrder, CreateReportData } from '../../types/report.types';

@Injectable()
export class ReportDatabaseRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findUserById(id: string): RepositoryResponse<User | null> {
    return this.safeRun(() => this.prisma.user.findUnique({ where: { id } }), 'Erro ao buscar usuário');
  }

  async findPostById(id: string): RepositoryResponse<Post | null> {
    return this.safeRun(() => this.prisma.post.findUnique({ where: { id } }), 'Erro ao buscar post');
  }

  async findConversationById(id: string): RepositoryResponse<DirectConversation | null> {
    return this.safeRun(() => this.prisma.directConversation.findUnique({ where: { id } }), 'Erro ao buscar conversa');
  }

  async findDirectMessageById(id: string): RepositoryResponse<DirectMessageWithConversation | null> {
    return this.safeRun(() => this.prisma.directMessage.findUnique({
      where: { id },
      include: { conversation: true },
    }), 'Erro ao buscar mensagem');
  }

  async findOrderById(id: string): RepositoryResponse<Order | null> {
    return this.safeRun(() => this.prisma.order.findUnique({ where: { id } }), 'Erro ao buscar pedido');
  }

  async findChatMessageById(id: string): RepositoryResponse<ChatMessageWithOrder | null> {
    return this.safeRun(() => this.prisma.chatMessage.findUnique({
      where: { id },
      include: { order: true },
    }), 'Erro ao buscar mensagem do chat');
  }

  async findReportByUnique(where: Prisma.ReportWhereUniqueInput): RepositoryResponse<Report | null> {
    return this.safeRun(() => this.prisma.report.findUnique({ where }), 'Erro ao buscar denúncia');
  }

  async createReport(data: CreateReportData): RepositoryResponse<Report> {
    return this.safeRun(() => {
      const prismaData: Prisma.ReportCreateInput = {
        reporter: { connect: { id: data.reporterId } },
        targetType: data.targetType,
        reason: data.reason,
        description: data.description,
        hideFromUser: data.hideFromUser,
      };
      if (data.reportedUserId) prismaData.reportedUser = { connect: { id: data.reportedUserId } };
      if (data.reportedPostId) prismaData.reportedPost = { connect: { id: data.reportedPostId } };
      if (data.reportedDirectConversationId) prismaData.reportedDirectConv = { connect: { id: data.reportedDirectConversationId } };
      if (data.reportedOrderChatId) prismaData.reportedOrder = { connect: { id: data.reportedOrderChatId } };
      if (data.reportedDirectMessageId) prismaData.reportedDirectMsg = { connect: { id: data.reportedDirectMessageId } };
      if (data.reportedChatMessageId) prismaData.reportedChatMsg = { connect: { id: data.reportedChatMessageId } };
      return this.prisma.report.create({ data: prismaData });
    }, 'Erro ao criar denúncia');
  }
}
