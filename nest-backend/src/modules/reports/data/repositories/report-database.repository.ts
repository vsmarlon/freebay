import { Injectable } from '@nestjs/common';
import { PrismaClient, Report, Prisma, User, Post, DirectConversation, Order } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ReportRepository } from '../../domain/repositories/report.repository';
import { DirectMessageWithConversation, ChatMessageWithOrder } from '../../types/report.types';

@Injectable()
export class ReportDatabaseRepository implements ReportRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findUserById(id: string): RepositoryResponse<User | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { id } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar usuário'));
    }
  }

  async findPostById(id: string): RepositoryResponse<Post | null> {
    try {
      return right(await this.prisma.post.findUnique({ where: { id } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar post'));
    }
  }

  async findConversationById(id: string): RepositoryResponse<DirectConversation | null> {
    try {
      return right(await this.prisma.directConversation.findUnique({ where: { id } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar conversa'));
    }
  }

  async findDirectMessageById(id: string): RepositoryResponse<DirectMessageWithConversation | null> {
    try {
      return right(await this.prisma.directMessage.findUnique({
        where: { id },
        include: { conversation: true },
      }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar mensagem'));
    }
  }

  async findOrderById(id: string): RepositoryResponse<Order | null> {
    try {
      return right(await this.prisma.order.findUnique({ where: { id } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar pedido'));
    }
  }

  async findChatMessageById(id: string): RepositoryResponse<ChatMessageWithOrder | null> {
    try {
      return right(await this.prisma.chatMessage.findUnique({
        where: { id },
        include: { order: true },
      }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar mensagem do chat'));
    }
  }

  async findReportByUnique(where: Prisma.ReportWhereUniqueInput): RepositoryResponse<Report | null> {
    try {
      return right(await this.prisma.report.findUnique({ where }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar denúncia'));
    }
  }

  async createReport(data: import('../../domain/repositories/report.repository').CreateReportData): RepositoryResponse<Report> {
    try {
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
      return right(await this.prisma.report.create({ data: prismaData }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar denúncia'));
    }
  }

  async findAllReports(where?: Prisma.ReportWhereInput): RepositoryResponse<Report[]> {
    try {
      return right(await this.prisma.report.findMany({
        where,
        orderBy: { createdAt: 'desc' },
      }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao listar denúncias'));
    }
  }

  async findReportById(id: string): RepositoryResponse<Report | null> {
    try {
      return right(await this.prisma.report.findUnique({ where: { id } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar denúncia'));
    }
  }

  async updateReport(id: string, data: Prisma.ReportUpdateInput): RepositoryResponse<Report> {
    try {
      return right(await this.prisma.report.update({ where: { id }, data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar denúncia'));
    }
  }

  async updateUser(id: string, data: Prisma.UserUpdateInput): RepositoryResponse<User> {
    try {
      return right(await this.prisma.user.update({ where: { id }, data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar usuário'));
    }
  }
}
