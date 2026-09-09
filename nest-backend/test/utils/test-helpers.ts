import { PrismaClient } from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
const { validateTestDatabaseUrl } = require('../../scripts/safe-prisma-db-push');

/**
 * Create a mock ConfigService for testing
 */
export function createMockConfigService(): ConfigService {
  const config = new Map<string, string | undefined>([
    ['DATABASE_URL', process.env.DATABASE_URL],
    ['REDIS_URL', process.env.REDIS_URL],
    ['JWT_SECRET', process.env.JWT_SECRET],
    ['JWT_REFRESH_SECRET', process.env.JWT_REFRESH_SECRET],
    ['JWT_EXPIRES_IN', process.env.JWT_EXPIRES_IN],
    ['JWT_REFRESH_EXPIRES_IN', process.env.JWT_REFRESH_EXPIRES_IN],
  ]);

  return {
    get: (key: string, defaultValue?: string) => config.get(key) ?? defaultValue,
  } as ConfigService;
}

/**
 * Hash a password using bcrypt
 */
export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 10);
}

/**
 * Generate a unique email for testing
 */
export function generateTestEmail(prefix: string = 'test'): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).substring(7)}@test.com`;
}

/**
 * Generate a unique CPF hash for testing
 */
export function generateTestCpfHash(): string {
  return `cpf-${Date.now()}-${Math.random().toString(36).substring(7)}`;
}

/**
 * Generate a unique username for testing
 */
export function generateTestUsername(): string {
  return `u${Date.now().toString(36)}${Math.random().toString(36).substring(2, 6)}`;
}

/**
 * Wait for a specified number of milliseconds
 */
export function wait(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Clean database (alternative to TRUNCATE)
 */
export async function cleanDatabase(prisma: PrismaClient): Promise<void> {
  assertSafeTestEnvironment();
  await prisma.$executeRawUnsafe(`TRUNCATE TABLE
    "WebMagicLink", "PasswordRecoveryCode", "PhoneVerificationCode", "MessageReaction",
    "ConversationPreference", "DirectMessage", "DirectConversation",
    "ChatMessage", "ReviewImage", "Review", "Dispute",
    "WalletEntry", "ConnectAccount", "PaymentGroup", "Transaction", "Order",
    "CartItem", "Favorite", "StoryView", "Story", "SavedPost", "Share",
    "CommentMention", "CommentLike", "Comment", "PostMention", "Like", "Post",
    "Block", "Follow", "Notification", "Report", "ModerationAction", "BugReport",
    "ProductImage", "Product", "Wallet", "User", "Category" CASCADE`);
}

export function assertSafeTestEnvironment(): void {
  if (process.env.NODE_ENV !== 'test' || !validateTestDatabaseUrl(process.env.DATABASE_URL)) {
    throw new Error('Refusing test database cleanup outside the configured test database');
  }
}
