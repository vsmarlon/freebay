# NestJS backend guidance

@../AGENTS.md

Use `Either<AppError, Output>` from the shared core for expected business outcomes. Controllers must preserve original errors when unwrapping; inspect the current `EitherInterceptor`, exception filter, and any shared unwrap helper before changing controller handling. Repository layering is intentionally mixed: inspect the owning module and follow the hardening decision against new ports rather than imposing a uniform folder layout.

Concrete repositories own Prisma/database access. Transaction callbacks use the transaction client for their queries and preserve established order and defaults. For transaction-runner work, follow P5 in [`../docs/HARDENING_PLAN.md`](../docs/HARDENING_PLAN.md). Use `nest-backend/package.json` as the source for runnable commands; integration and E2E require guarded test DB configuration.
