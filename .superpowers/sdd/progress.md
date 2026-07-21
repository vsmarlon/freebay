# Production Hardening — Progress Ledger

Plan: docs/superpowers/plans/2026-07-21-production-hardening.md
Branch: feat/production-hardening
Base commit: 261f66d

Mode: manual execution (phases are sequential/coupled), not implementer+reviewer-per-task.

## Status

- [x] Phase 1 — Schema & data foundations (username backfilled 4/4 unique, WithdrawalStatus enum, Report.reportedPostId index)
- [ ] Phase 2 — Feed algorithm (backend)
- [ ] Phase 3 — Feed frontend + full-page scroll
- [~] Phase 4 — Username: BACKEND DONE (register/update-profile validate+check uniqueness, GET /auth/username-available, UserResponse.username). Frontend (registration field, edit_profile, @username rendering) still TODO — doing it next, then will mark this phase fully complete.
  NOTE: reordered Phase 4 backend to run immediately after Phase 1 (not after Phase 2/3) because username is NOT NULL in schema and broke register.usecase.ts / test factory compilation.
- [ ] Phase 5 — User search + dedicated people-search screen
- [ ] Phase 6 — Profile friend suggestions
- [ ] Phase 7 — Chat: unify order+direct, replies, reactions, polish
- [ ] Phase 8 — Shared upload foundation
- [ ] Phase 9 — Wallet (frontend + backend cleanup)
- [ ] Phase 10 — Product search + category cleanup
- [ ] Phase 11 — Backend dead-code cleanup & conventions
- [ ] Phase 12 — Security pass (default-deny) + closing review
- [ ] Phase 13 — Final verification
