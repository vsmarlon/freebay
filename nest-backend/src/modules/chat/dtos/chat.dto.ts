import {
  IsString,
  IsUUID,
  IsOptional,
  IsBoolean,
  IsArray,
  ArrayNotEmpty,
  ArrayMaxSize,
  Matches,
  IsEnum,
  IsInt,
  Max,
  Min,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';
import { STORED_MEDIA_PATH } from '@/shared/utils/file.utils';
import { ChatTheme, ChatThreadType, ConversationStatus, MessageType } from '@prisma/client';

export const FORWARD_MESSAGE_MAX_COUNT = 50;
export const AUDIO_DURATION_MAX_MS = 60_000;
export const FILTERED_MESSAGES_DEFAULT_LIMIT = 50;

export class VerifyUrlDTO {
  @ApiProperty({ example: 'https://google.com' })
  @IsString()
  readonly url: string;
}

export class ForwardMessagesDTO {
  @ApiProperty({ type: [String], example: ['550e8400-e29b-41d4-a716-446655440000'] })
  @IsArray()
  @IsUUID('4', { each: true })
  @ArrayNotEmpty()
  @ArrayMaxSize(FORWARD_MESSAGE_MAX_COUNT)
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

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000', required: false })
  @IsOptional()
  @IsUUID()
  readonly productId?: string;
}

export class MarkMessagesReadDTO {
  @ApiProperty({ required: false, description: 'Only this message was explicitly opened; omitted means ordinary messages only' })
  @IsOptional()
  @IsUUID('4')
  readonly messageId?: string;
}

export class SendMessageDTO {
  @ApiProperty({ example: 'Olá!', required: false })
  @IsString()
  @IsOptional()
  @SanitizeText()
  readonly content?: string;

  @ApiProperty({ required: false, description: 'Client-generated id for optimistic reconciliation and idempotency' })
  @IsString()
  @IsOptional()
  readonly clientMessageId?: string;

  @ApiProperty({ enum: MessageType, default: MessageType.TEXT, required: false })
  @IsEnum(MessageType)
  @IsOptional()
  readonly type?: MessageType;

  @ApiProperty({
    example: '/media/chat/550e8400-e29b-41d4-a716-446655440000.jpg',
    required: false,
  })
  @IsString()
  @IsOptional()
  @Matches(STORED_MEDIA_PATH, {
    message: 'attachmentUrl deve ser um caminho de upload válido',
  })
  readonly attachmentUrl?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  readonly replyToId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  readonly metadata?: Record<string, unknown>;

  @ApiProperty({ required: false, description: 'Audio duration in milliseconds' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(AUDIO_DURATION_MAX_MS)
  readonly durationMs?: number;

  @ApiProperty({ required: false, description: 'Message self-destructs after being seen' })
  @IsBoolean()
  @IsOptional()
  readonly viewOnce?: boolean;
}

export class StartConversationOutput {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly conversationId: string;

  @ApiProperty({ example: 'PENDING' })
  readonly status: string;
  readonly threadType: ChatThreadType;
  readonly otherUser: ConversationCounterpartSummary;
  readonly product: ProductConversationSummary | null;
}

export interface ConversationCounterpartSummary {
  id: string;
  displayName: string;
  avatarUrl: string | null;
}

export interface ProductConversationSummary {
  id: string;
  title: string;
  imageUrl: string | null;
  status: string;
}

export class AcceptConversationOutput {
  @ApiProperty({ example: true })
  readonly accepted: boolean;
}

export interface SendMessageInput {
  senderId: string;
  conversationId: string;
  clientMessageId?: string;
  content?: string;
  type?: MessageType;
  attachmentUrl?: string;
  replyToId?: string;
  metadata?: Record<string, unknown>;
  viewOnce?: boolean;
  durationMs?: number;
}

export interface SendMessageOutput {
  id: string;
  conversationId: string;
  senderId: string;
  clientMessageId: string | null;
  content: string | null;
  type: string;
  attachmentUrl: string | null;
  metadata: Record<string, unknown> | null;
  replyToId: string | null;
  viewOnce: boolean;
  createdAt: Date;
}

export interface SendMessageInternalOutput {
  message: SendMessageOutput;
  recipientId: string;
  senderName: string;
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
  status: ConversationStatus;
  createdAt: Date;
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
  type?: MessageType;
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
  productId?: string;
}

export interface AcceptConversationInput {
  conversationId: string;
  userId: string;
}

export class UpdatePreferenceDTO {
  @ApiProperty({ enum: ChatTheme, example: ChatTheme.DEFAULT })
  @IsEnum(ChatTheme)
  readonly theme: ChatTheme;
}

export interface ConversationPreferenceSummary {
  isArchived: boolean;
  theme: string;
  backgroundUrl: string | null;
}

export interface ConversationOtherUserSummary {
  id: string;
  displayName: string;
  avatarUrl: string | null;
}

export interface GetMessagesResult {
  messages: GetMessagesOutput[];
  hasMore: boolean;
  nextCursor: string | null;
  threadType: ChatThreadType;
  otherUserId: string;
  otherUser: ConversationOtherUserSummary;
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
