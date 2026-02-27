import path from 'node:path';
import { defineConfig } from 'prisma/config';
import * as dotenv from 'dotenv';

dotenv.config();

export default defineConfig({
    earlyAccess: true,
    schema: path.join(__dirname, 'prisma', 'schema.prisma'),
    datasource: {
        url: process.env.DATABASE_URL, 
    },
    migrate: {
        adapter: async () => {
            const { Pool } = await import('pg');
            const { PrismaPg } = await import('@prisma/adapter-pg');
            if (!process.env.DATABASE_URL) {
                throw new Error("DATABASE_URL is not defined in environment variables");
            }
            const pool = new Pool({connectionString: process.env.DATABASE_URL});
            return new PrismaPg(pool);
        },
    },
});