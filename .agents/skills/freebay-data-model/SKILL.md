---
name: freebay-data-model
description: Use when changing FreeBay Prisma schema, database models, relations, indexes, or data constraints.
---

# Prisma data model

Read `nest-backend/prisma/schema.prisma` and inspect current callers/records before editing. Use the repository hardening plan for phase decisions when available; read [`freebay-prisma`](../freebay-prisma/SKILL.md) for sync/drift verification.

- Money remains `Int` cents; preserve existing monetary semantics and avoid money-path refactors absent explicit approval.
- Use Prisma enums for closed state sets. Give every relation deliberate `onDelete` behavior and index queried foreign keys; check uniqueness and query patterns rather than adding speculative indexes.
- Schema is authoritative. Development synchronization is `npm run db:sync`; seed only the intended disposable development DB. Tests use the guarded `.env.test` / `freebay_test_db` path. Never sync/seed a non-test database as test setup.
- Agents do not create or run migrations. Migration workflow is owner-only P10; production release remains migration-gated. Do not claim `db push` proves runtime schema currency.

Verify generated client and database target explicitly. Report schema/client/test DB/runtime DB evidence separately; never include credentials in evidence.
