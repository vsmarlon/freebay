---
name: freebay-prisma
description: Use when syncing the Prisma schema to a database, diagnosing Prisma P2022 column-not-found drift, regenerating the Prisma client, or verifying a query against the real runtime database in FreeBay.
---

# FreeBay Prisma Workflow

Prisma ORM 7 with PostgreSQL over the `adapter-pg` driver adapter. `nest-backend/prisma/schema.prisma` is the single source of truth for the data model; modeling rules (cents-as-Int, enums, `onDelete`, indexes) live in `freebay-data-model` and are not repeated here.

## Runtime wiring

- Connection URL comes from `DATABASE_URL` via `nest-backend/prisma.config.ts` (`defineConfig` + `env('DATABASE_URL')`). There is no URL in the `datasource db` block.
- The running app connects through `PrismaService`: `pg` `Pool` → `PrismaPg` adapter → `PrismaClient`. Tests that substitute this path cannot prove the runtime database is current.

## Development database sync

Pre-production project: schema-sync only. Never create or run migrations, never add `prisma/migrations`.

```bash
cd nest-backend
npm run db:sync    # prisma db push && prisma generate
npm run db:seed    # idempotent development seed
```

`prisma db push` applies the schema directly without migration files; Prisma 7 requires the explicit `prisma generate` afterward. `db push` can warn about data loss when adding unique constraints — resolve the warning with evidence (duplicate check), not by defaulting to `--force-reset`, which drops data.

## Test database isolation

Integration tests target a different database (`freebay_test_db`) and synchronize it through the guarded `scripts/safe-prisma-db-push.js` entrypoint: `NODE_ENV=test`, localhost only, that database name only. A green integration run proves the test database was synced; it says nothing about the runtime database.

## Diagnose P2022 drift

`PrismaClientKnownRequestError` code `P2022` (PostgreSQL `42703`, column does not exist) means the generated client expects a column the connected database lacks. Confirm against the app's database, not the test one:

1. Record the actual identity: `SELECT current_database(), current_schema()`.
2. Compare `Prisma.dmmf` scalar fields against `information_schema.columns` for the connected database.
3. Confirm the pending delta without applying it: `npx prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --exit-code`.

## Real-database verification

Repository mocks cannot verify columns, constraints, transactions, or query behavior. The regression seam for drift is the real repository against the configured database:

```bash
cd nest-backend
npm run test:runtime-db
```

That spec reads through `TransactionDatabaseRepository.findTransferFailures` on the `DATABASE_URL` target over a PostgreSQL-enforced read-only connection, asserts the read-only flag, and writes no fixtures. Store RED/GREEN output plus the tested revision under `docs/test-runs/<date>/`. Never paste credentials into reports — database/schema identity only.
