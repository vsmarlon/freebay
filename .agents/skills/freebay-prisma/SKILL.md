---
name: freebay-prisma
description: Use when syncing Prisma, diagnosing P2022 drift, regenerating the client, or verifying FreeBay against its actual database.
---

# Prisma runtime and drift

Read `freebay-data-model` for schema rules. Runtime uses `DATABASE_URL` from `nest-backend/prisma.config.ts` and `PrismaService` with `pg`/`PrismaPg`; a mocked adapter or synchronized test DB does not establish runtime schema state.

- Development schema workflow: `npm run db:sync` then `npm run db:seed` only against intended development data. Tests use guarded `.env.test` / `freebay_test_db`; never point test setup at a non-test DB.
- P2022 means the connected database lacks a column expected by the generated client. Identify the actual database/schema safely, compare runtime columns to schema/client, and verify via the project’s runtime DB check if configured. Do not run `db push` as diagnosis or use destructive reset to silence drift.
- Agents do not create/run migrations; P10 is owner-only. Production schema readiness requires owner migration workflow, not `db push`.

Report which database was actually queried, command/result and revision. Keep credentials out of logs/reports. Distinguish test-DB, runtime-DB and generated-client evidence.
