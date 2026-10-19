---
name: freebay-system-design
description: Use when making a cross-layer FreeBay architecture or module-boundary decision.
---

# Architecture map

FreeBay is a Flutter client, NestJS API, PostgreSQL/Prisma persistence, Redis-backed facilities and Socket.IO chat. Treat `docs/FEATURE_TRUTH.md` as current capability status, `docs/HARDENING_PLAN.md` as phase decisions, `frontend/DESIGN.md` as UI-token authority, and `nest-backend/prisma/schema.prisma` as schema authority. Read only the owner reference needed for the task.

## Architecture references

- Backend target and decision status: [ADR 0004](../../../docs/adr/0004-selective-modular-backend-architecture.md) and [backend architecture plan](../../../docs/BACKEND_ARCHITECTURE_PLAN.md). Phase order and safety gates: [hardening plan](../../../docs/HARDENING_PLAN.md).
- Frontend HTTP repositories call backend only. Keep established domain repository contracts; domain use cases exist for meaningful logic, not unchanged single-call forwarding. Domain may use data entities but not data repositories. Avoid forcing layers into legacy features.
- Preserve `EitherInterceptor` error/status behavior and original `AppError`. Keep money as integer cents and financial transaction semantics intact. External provider calls are not repository responsibilities.
- Use `AppRoutes`, Riverpod and design-system tokens. Security/privacy boundaries are enforced server-side; tests and docs distinguish intended behavior from proof.

For route owners, payment lifecycle, data relationships, security, test commands and release gaps, use source plus the focused skill/docs. Do not maintain duplicate schema inventories or aspirational architecture diagrams here.
