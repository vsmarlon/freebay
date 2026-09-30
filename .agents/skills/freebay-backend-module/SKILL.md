---
name: freebay-backend-module
description: Use when changing a NestJS module, DTO, controller, use case, or Prisma repository in FreeBay.
---

# Backend vertical slice

Before changing behavior, read root [`AGENTS.md`](../../../AGENTS.md), `docs/FEATURE_TRUTH.md` for capability claims, and `test-audit` when touching tests. Prefer a real HTTP/DB boundary; establish intended behavioral RED before production edits. Follow repository scripts for exact gates.

## Implementation

- Inspect the feature's actual layout first. DTOs use `class-validator` and Swagger decorators. Keep public response projections explicit; never serialize raw user records.
- Use cases are one class per file and return `Either<AppError, Output>`; expected business errors are `left(AppError)`. Controllers follow local conventions and preserve original error status/mapping.
- New use cases depend directly on concrete `ThingDatabaseRepository` classes: do not add abstract backend repository ports. The existing five/six legacy ports are not a mandate to add more. `TransactionRunner` is a future P5-only exception; do not introduce it now.
- Repositories own database access only (Prisma/SQL/transactions); use typed Prisma payloads and `repositoryResponse`. External HTTP belongs outside repositories. Class names follow the established `ThingDatabaseRepository` role; do not rename files or DI tokens as part of naming changes.
- Transactions are money-sensitive: preserve query order, atomicity and integer-cent amounts. Do not refactor financial paths without explicit scope/approval.
- No `any`, `as any`, or `as unknown as`. Narrow unknown input or fix the declared contract.

## Finish

Run the focused owner-boundary test and applicable checks from `AGENTS.md` / `nest-backend/package.json`; report exact command, result and blockers. Record E2E evidence at `docs/test-runs/<date>/` with revision, safe environment identity, reset/fixture steps and actual outcomes. Do not imply mocked or test-DB evidence proves runtime DB/provider/device behavior.
