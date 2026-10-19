---
name: freebay-backend-module
description: Use when changing a NestJS module, DTO, controller, use case, or Prisma repository in FreeBay.
---

# Backend vertical slice

Before changing behavior, read root [`AGENTS.md`](../../../AGENTS.md), `docs/FEATURE_TRUTH.md` for capability claims, and `test-audit` when touching tests. Prefer focused verification at a real HTTP/DB boundary. Follow repository scripts for exact gates.

## Implementation

- Inspect the feature's actual layout first. DTOs use `class-validator` and Swagger decorators. Keep public response projections explicit; never serialize raw user records.
- Use cases are one class per file and return `Either<AppError, Output>`; expected business errors are `left(AppError)`. Controllers follow local conventions and preserve original error status/mapping.
- Follow [ADR 0004](../../../docs/adr/0004-selective-modular-backend-architecture.md) and [the backend architecture plan](../../../docs/BACKEND_ARCHITECTURE_PLAN.md) for target and current decision status. Read [the hardening plan](../../../docs/HARDENING_PLAN.md) for phase gates before financial refactors.
- Repositories own database access only (Prisma/SQL/transactions); use typed Prisma payloads and `repositoryResponse`. External HTTP belongs outside repositories. Class names follow the established `ThingDatabaseRepository` role; do not rename files or DI tokens as part of naming changes.
- For transaction work, preserve query order, atomicity and integer-cent amounts; follow the hardening plan's approval gates.
- No `any`, `as any`, or `as unknown as`. Narrow unknown input or fix the declared contract.

## Finish

Run the focused owner-boundary test and applicable checks from `AGENTS.md` / `nest-backend/package.json`; report exact command, result and blockers. Record E2E evidence at `docs/test-runs/<date>/` with revision, safe environment identity, reset/fixture steps and actual outcomes. Do not imply mocked or test-DB evidence proves runtime DB/provider/device behavior.
