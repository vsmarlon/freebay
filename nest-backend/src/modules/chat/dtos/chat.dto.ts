import { IsString, IsUUID, IsOptional, IsBoolean, IsArray, ArrayNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';
import { ChatThreadType } from '@prisma/client';

export class VerifyUrlDTO {
  @ApiProperty({ example: 'https://google.com' })
  @IsString()
  readonly url: string;
}

export class ForwardMessagesDTO {
  @ApiProperty({ type: [String], example: ['550e8400-e29b-41d4-a716-446655440000'] })
  @IsArray()
  @IsString({ each: true })
  @ArrayNotEmpty()
  readonly messageIds: string[];

  @ApiProperty({ type: [String], example: ['550e8400-e29b-41d4-a716-446655440001'] })
  @IsArray()
  @IsString({ each: true })
  @ArrayNotEmpty()
  readonly targetConversationIds: string[];

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440002', required: false })
  @IsOptional()
  @IsString()
  readonly sourceConversationId?: string;
}

export class StartConversationDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly targetUserId: string;
}

export class SendMessageDTO {
  @ApiProperty({ example: 'Olá!', required: false })
  @IsString()
  @IsOptional()
  @SanitizeText()
  readonly content?: string;

  @ApiProperty({ enum: ['TEXT', 'IMAGE', 'GIF', 'AUDIO', 'LOCATION', 'PRODUCT_CARD'], default: 'TEXT', required: false })
  @IsString()
  @IsOptional()
  readonly type?: 'TEXT' | 'IMAGE' | 'GIF' | 'AUDIO' | 'LOCATION' | 'PRODUCT_CARD';

  @ApiProperty({ example: '/uploads/chat/abc.jpg', required: false })
  @IsString()
  @IsOptional()
  readonly attachmentUrl?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  readonly replyToId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  readonly metadata?: Record<string, unknown>;

  @ApiProperty({ required: false, description: 'Message self-destructs after being seen' })
  @IsBoolean()
  @IsOptional()
  readonly viewOnce?: boolean;
}

export class ConversationResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id: string;

  @ApiProperty({
    example: { id: 'uuid', displayName: 'John Doe', avatarUrl: null, isVerified: true },
  })
  readonly otherUser: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };

  @ApiProperty({ example: { content: 'Last message', createdAt: '2026-06-17T12:00:00.000Z' }, nullable: true })
  readonly lastMessage: { content: string; createdAt: Date } | null;

  @ApiProperty({ example: 3 })
  readonly unreadCount: number;

  @ApiProperty({ example: 'ACTIVE' })
  readonly status: 'ACTIVE' | 'PENDING';

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  readonly createdAt: Date;
}

export class MessageResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly conversationId: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly senderId: string;

  @ApiProperty({ example: 'Olá, ainda tem disponível?' })
  readonly content: string | null;

  @ApiProperty({ example: 'TEXT' })
  readonly type: string;

  @ApiProperty({ example: null, nullable: true })
  readonly readAt: Date | null;

  @ApiProperty({ example: null, nullable: true })
  readonly deliveredAt: Date | null;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  readonly createdAt: Date;
}

export class StartConversationOutput {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly conversationId: string;

  @ApiProperty({ example: 'PENDING' })
  readonly status: string;
}

export class AcceptConversationOutput {
  @ApiProperty({ example: true })
  readonly accepted: boolean;
}

export interface SendMessageInput {
  senderId: string;
  conversationId: string;
  content?: string;
  type?: 'TEXT' | 'IMAGE' | 'GIF' | 'AUDIO' | 'LOCATION' | 'PRODUCT_CARD';
  attachmentUrl?: string;
  replyToId?: string;
  metadata?: Record<string, unknown>;
  viewOnce?: boolean;
}

export interface SendMessageOutput {
  id: string;
  conversationId: string;
  senderId: string;
  content: string | null;
  type: string;
  attachmentUrl: string | null;
  metadata: Record<string, unknown> | null;
  replyToId: string | null;
  viewOnce: boolean;
  createdAt: Date;
}

export interface GetConversationsInput {
  userId: string;
}

export interface ConversationWithStatus {
  id: string;
  otherUser: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
  lastMessage: {
    content: string;
    createdAt: Date;
  } | null;
  unreadCount: number;
  status: 'ACTIVE' | 'PENDING';
  createdAt: Date;
}

export interface GetMessagesInput {
  conversationId: string;
  userId: string;
}

export interface ReplyToOutput {
  id: string;
  senderId: string;
  content: string | null;
  type: string;
  attachmentUrl: string | null;
  deletedAt: Date | null;
  conversationId: string;
  createdAt: Date;
  viewOnce: boolean;
  readAt: Date | null;
}

export interface GetMessagesOutput {
  id: string;
  conversationId: string;
  senderId: string;
  content: string | null;
  type: string;
  attachmentUrl: string | null;
  metadata: Record<string, unknown> | null;
  replyToId: string | null;
  replyTo: ReplyToOutput | null;
  deletedAt: Date | null;
  readAt: Date | null;
  deliveredAt: Date | null;
  createdAt: Date;
  viewOnce: boolean;
}

export interface GetFilteredMessagesInput {
  conversationId: string;
  userId: string;
  type?: string;
  limit?: number;
  cursor?: string;
}

export interface GetFilteredMessagesResult {
  messages: GetMessagesOutput[];
  nextCursor: string | null;
}

export interface StartConversationInput {
  initiatorId: string;
  targetUserId: string;
}

export interface AcceptConversationInput {
  conversationId: string;
  userId: string;
}

export class UpdatePreferenceDTO {
  @ApiProperty({ enum: ['DEFAULT', 'CRIMSON', 'COBALT', 'FOREST', 'AMBER', 'SLATE'], example: 'DEFAULT' })
  @IsString()
  readonly theme: string;
}

export interface ConversationPreferenceSummary {
  isArchived: boolean;
  theme: string;
  backgroundUrl: string | null;
}

export interface GetMessagesResult {
  messages: GetMessagesOutput[];
  threadType: ChatThreadType;
  otherUserId: string;
  preference: ConversationPreferenceSummary | null;
}

export interface ForwardMessagesInput {
  userId: string;
  messageIds: string[];
  targetConversationIds: string[];
  sourceConversationId?: string;
}

export interface ForwardMessagesOutput {
  forwardedCount: number;
  messages: SendMessageOutput[];
}

