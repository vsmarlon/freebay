import { ChatTheme } from '@prisma/client';

export interface UpsertPreferenceInput {
  userId: string;
  orderId?: string;
  directConversationId?: string;
  isArchived?: boolean;
  isDeleted?: boolean;
  theme?: ChatTheme;
  backgroundUrl?: string | null;
}
