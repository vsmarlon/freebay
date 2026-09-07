import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { assertSafeTestEnvironment, cleanDatabase } from './utils/test-helpers';
// Create a dedicated Prisma client for testing with pg adapter
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  allowExitOnIdle: true,
});
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
  assertSafeTestEnvironment();

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
  await cleanDatabase(prisma);
});

afterAll(async () => {
  await prisma.$disconnect();
  await pool.end();
});
