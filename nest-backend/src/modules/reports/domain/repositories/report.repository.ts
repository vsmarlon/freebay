import { RepositoryResponse } from '@/shared/core/either';
import { Report, Prisma, User, Post, DirectConversation, Order } from '@prisma/client';
import { DirectMessageWithConversation, ChatMessageWithOrder, CreateReportData } from '../../types/report.types';

export abstract class ReportRepository {
  abstract findUserById(id: string): RepositoryResponse<User | null>;
  abstract findPostById(id: string): RepositoryResponse<Post | null>;
  abstract findConversationById(id: string): RepositoryResponse<DirectConversation | null>;
  abstract findDirectMessageById(id: string): RepositoryResponse<DirectMessageWithConversation | null>;
  abstract findOrderById(id: string): RepositoryResponse<Order | null>;
  abstract findChatMessageById(id: string): RepositoryResponse<ChatMessageWithOrder | null>;
  abstract findReportByUnique(where: Prisma.ReportWhereUniqueInput): RepositoryResponse<Report | null>;
  abstract createReport(data: CreateReportData): RepositoryResponse<Report>;
  abstract findAllReports(where?: Prisma.ReportWhereInput): RepositoryResponse<Report[]>;
  abstract findReportById(id: string): RepositoryResponse<Report | null>;
  abstract updateReport(id: string, data: Prisma.ReportUpdateInput): RepositoryResponse<Report>;
  abstract updateUser(id: string, data: Prisma.UserUpdateInput): RepositoryResponse<User>;
}
