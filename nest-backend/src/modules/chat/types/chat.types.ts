import { ChatTheme } from '@prisma/client';

export interface UpsertPreferenceInput {
  userId: string;
  orderId?: string;
  directConversationId?: string;
  isArchived?: boolean;
  isDeleted?: boolean;
  theme?: ChatTheme;
  muted?: boolean;
  backgroundUrl?: string | null;
}

export interface ResolvedChatThread {
  orderId?: string;
  directConversationId?: string;
  otherUserId: string;
  orderStatus?: string;
}

export interface OgMetadata {
  title: string | null;
  description: string | null;
  imageUrl: string | null;
  siteName: string | null;
  url: string;
}

export enum UrlRiskLevel {
  SAFE = 'SAFE',
  SUSPICIOUS = 'SUSPICIOUS',
  DANGEROUS = 'DANGEROUS',
}

export interface UrlSafetyVerification {
  url: string;
  normalizedUrl: string;
  host: string;
  isSafe: boolean;
  riskLevel: UrlRiskLevel;
  riskReasons: string[];
  destinationDomain: string;
}

export interface ReactionSummary {
  emoji: string;
  count: number;
  userIds: string[];
}
