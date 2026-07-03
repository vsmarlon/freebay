import { Layer, Effect } from 'effect';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { PrismaTag } from './tags';

export const LivePrismaLayer = Layer.effect(
  PrismaTag,
  Effect.sync(() => {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      allowExitOnIdle: true,
    });
    const adapter = new PrismaPg(pool);
    return new PrismaClient({ adapter });
  }),
);
