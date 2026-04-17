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

export interface StartConversationOutput {
  conversationId: string;
  status: string;
}

export interface AcceptConversationInput {
  conversationId: string;
  userId: string;
}

export interface AcceptConversationOutput {
  accepted: boolean;
}
