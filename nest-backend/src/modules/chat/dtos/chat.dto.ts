import { IsString, IsNotEmpty, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class StartConversationDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  targetUserId: string;
}

export class SendMessageDTO {
  @ApiProperty({ example: 'Olá, ainda tem disponível?' })
  @IsString()
  @IsNotEmpty()
  @SanitizeText()
  content: string;
}

export class ConversationResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({
    example: { id: 'uuid', displayName: 'John Doe', avatarUrl: null, isVerified: true },
  })
  otherUser: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };

  @ApiProperty({ example: { content: 'Last message', createdAt: '2026-06-17T12:00:00.000Z' }, nullable: true })
  lastMessage: { content: string; createdAt: Date } | null;

  @ApiProperty({ example: 3 })
  unreadCount: number;

  @ApiProperty({ example: 'ACTIVE' })
  status: 'ACTIVE' | 'PENDING';

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  createdAt: Date;
}

export class MessageResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  conversationId: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  senderId: string;

  @ApiProperty({ example: 'Olá, ainda tem disponível?' })
  content: string | null;

  @ApiProperty({ example: 'TEXT' })
  type: string;

  @ApiProperty({ example: null, nullable: true })
  readAt: Date | null;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  createdAt: Date;
}

export class StartConversationOutput {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  conversationId: string;

  @ApiProperty({ example: 'PENDING' })
  status: string;
}

export class AcceptConversationOutput {
  @ApiProperty({ example: true })
  accepted: boolean;
}

export interface SendMessageInput {
  senderId: string;
  conversationId: string;
  content: string;
}

export interface SendMessageOutput {
  id: string;
  conversationId: string;
  senderId: string;
  content: string;
  type: string;
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
