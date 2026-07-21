# Production Hardening — Progress Ledger

Plan: docs/superpowers/plans/2026-07-21-production-hardening.md
Branch: feat/production-hardening
Base commit: 261f66d

Mode: manual execution (phases are sequential/coupled), not implementer+reviewer-per-task.

## Status

- [x] Phase 1 — Schema & data foundations (username backfilled 4/4 unique, WithdrawalStatus enum, Report.reportedPostId index)
- [ ] Phase 2 — Feed algorithm (backend)
- [ ] Phase 3 — Feed frontend + full-page scroll
- [x] Phase 4 — Username (backend + frontend). Register/edit-profile validate+check uniqueness, GET /auth/username-available, reusable UsernameField component (core/components/username_field.dart, debounced check via ValueUtils.validateUsername), @username rendered on profile header + user search cards. flutter analyze: 0 issues.
  NOTE: reordered Phase 4 to run immediately after Phase 1 (not after Phase 2/3) because username is NOT NULL in schema and broke register.usecase.ts / test factory compilation.
- [ ] Phase 5 — User search + dedicated people-search screen
- [ ] Phase 6 — Profile friend suggestions
- [ ] Phase 7 — Chat: unify order+direct, replies, reactions, polish
- [ ] Phase 8 — Shared upload foundation
- [ ] Phase 9 — Wallet (frontend + backend cleanup)
- [ ] Phase 10 — Product search + category cleanup
- [ ] Phase 11 — Backend dead-code cleanup & conventions
- [ ] Phase 12 — Security pass (default-deny) + closing review
- [ ] Phase 13 — Final verification
