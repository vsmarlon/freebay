import { IsString, IsUUID, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export type ChatThreadTypeParam = 'ORDER' | 'DIRECT';

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

  @ApiProperty({ enum: ['TEXT', 'IMAGE', 'GIF', 'LOCATION', 'PRODUCT_CARD'], default: 'TEXT', required: false })
  @IsString()
  @IsOptional()
  readonly type?: 'TEXT' | 'IMAGE' | 'GIF' | 'LOCATION' | 'PRODUCT_CARD';

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
  type?: 'TEXT' | 'IMAGE' | 'GIF' | 'LOCATION' | 'PRODUCT_CARD';
  attachmentUrl?: string;
  replyToId?: string;
  metadata?: Record<string, unknown>;
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

export interface GetMessagesOutput {
  id: string;
  conversationId: string;
  senderId: string;
  content: string | null;
  type: string;
  readAt: Date | null;
  deliveredAt: Date | null;
  createdAt: Date;
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
  threadType: ChatThreadTypeParam;
  otherUserId: string;
  preference: ConversationPreferenceSummary | null;
}
