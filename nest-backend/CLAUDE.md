# NestJS backend guidance

@../AGENTS.md

Backend target: [ADR 0004](../docs/adr/0004-selective-modular-backend-architecture.md) and [ADR 0005](../docs/adr/0005-module-template-public-api-uow-events.md); active scope/status: [architecture plan](../docs/BACKEND_ARCHITECTURE_PLAN.md); phase and safety gates: [hardening plan](../docs/HARDENING_PLAN.md). Implementation examples: [backend guide](../docs/BACKEND_IMPLEMENTATION_GUIDE.md). Preserve existing `EitherInterceptor`, exception-filter, error and status behavior when changing HTTP handling.

Use `nest-backend/package.json` as the source for runnable commands. Integration and E2E require guarded test DB configuration.
