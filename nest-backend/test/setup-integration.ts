import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
// Create a dedicated Prisma client for testing with pg adapter
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
export const prisma = new PrismaClient({
  adapter,
  log: ['error', 'warn'],
});

beforeAll(async () => {
  // Ensure we're running in test environment
  if (process.env.NODE_ENV !== 'test') {
    throw new Error('Tests must run with NODE_ENV=test');
  }

  // Check if we're connected to test database
  const dbUrl = process.env.DATABASE_URL || '';
  if (!dbUrl.includes('freebay_test')) {
    throw new Error('Tests must run against freebay_test database');
  }

  try {
    // Connect to database
    await prisma.$connect();
    console.log('Test database connected');
  } catch (error) {
    console.error('Failed to connect to test database:', error);
    throw error;
  }
});

afterEach(async () => {
  // Clean up data after each test
  // Delete in correct order to respect foreign key constraints
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
      await prisma.$executeRawUnsafe(`TRUNCATE TABLE "${tableName}" CASCADE`);
    } catch {
      // Table might not exist yet, ignore
    }
  }
});

afterAll(async () => {
  await prisma.$disconnect();
});
