import { PrismaClient } from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';

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
 * Wait for a specified number of milliseconds
 */
export function wait(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Clean database (alternative to TRUNCATE)
 */
export async function cleanDatabase(prisma: PrismaClient): Promise<void> {
  const tableNames = [
    'Review',
    'Dispute',
    'Withdrawal',
    'Transaction',
    'Order',
    'ChatMessage',
    'DirectMessage',
    'DirectConversation',
    'StoryView',
    'Story',
    'Share',
    'CommentLike',
    'Comment',
    'Like',
    'Post',
    'ProductImage',
    'Product',
    'Wallet',
    'Block',
    'Follow',
    'Notification',
    'Report',
    'User',
    'Category',
  ];

  for (const tableName of tableNames) {
    try {
      await prisma.$executeRawUnsafe(`DELETE FROM "${tableName}"`);
    } catch {
      // Ignore errors for tables that don't exist
    }
  }
}
