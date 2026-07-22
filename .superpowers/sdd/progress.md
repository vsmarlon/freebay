# Production Hardening — Progress Ledger

Plan: docs/superpowers/plans/2026-07-21-production-hardening.md
Branch: feat/production-hardening
Base commit: 261f66d

Mode: manual execution (phases are sequential/coupled), not implementer+reviewer-per-task.

## Status

- [x] Phase 1 — Schema & data foundations (username backfilled 4/4 unique, WithdrawalStatus enum, Report.reportedPostId index)
- [x] Phase 2 — Feed algorithm (backend): findFeed split into keyset-paginated `following` + ranked/offset-paginated `explore` (engagement*recency-decay*affinity, 300-candidate window). Block-exclusion via Prisma relation filter (blocksGiven/blocksReceived none). contentFilter (all/social/selling) maps to Post.type. Verified query syntax against real dev DB + npx jest src/modules/social green.
- [x] Phase 3 — Feed frontend + full-page scroll: FeedPageResult (posts+hasMore+nextCursor+nextOffset) replaces the length>=20 heuristic; per-mode cursor(following)/offset(explore) tracking in FeedNotifier; real scroll-triggered loadMore (ScrollEndNotification + extentAfter<400); contentFilter now sent server-side (removed client-side post-filter that broke pagination math). Full-page scroll (HideOnScrollController/ScrollAwareBar, no black bar) was already present in feed_page.dart from a prior session — verified, not re-done. flutter analyze: 0 issues.
- [x] Phase 4 — Username (backend + frontend). Register/edit-profile validate+check uniqueness, GET /auth/username-available, reusable UsernameField component (core/components/username_field.dart, debounced check via ValueUtils.validateUsername), @username rendered on profile header + user search cards. flutter analyze: 0 issues.
  NOTE: reordered Phase 4 to run immediately after Phase 1 (not after Phase 2/3) because username is NOT NULL in schema and broke register.usecase.ts / test factory compilation.
- [x] Phase 5 — User search + dedicated people-search screen. FULLY DONE. Committed 38d9a21.
  - Backend: `$queryRaw` ranked search (exact/prefix/contains username match, followersCount desc, block-exclusion), offset-paginated `{users, hasMore, nextOffset}`.
  - Frontend: `people_search_page.dart` (new dedicated screen, PageHeader + debounced AppTextField + UserSearchList, empty pre-search state), `AppRoutes.peopleSearch = '/people/search'` + GoRoute registered in `app_router.dart`, search icon (`person_search_outlined`) added to feed header in `feed_page.dart`, `explorar_page.dart` stripped to products-only (no TabController/TabBar/TabBarView/Pessoas tab/userSearchProvider/UserSearchList imports). `flutter analyze`: 0 issues.
- [ ] Phase 6 — Profile friend suggestions
- [ ] Phase 7 — Chat: unify order+direct, replies, reactions, polish
- [ ] Phase 8 — Shared upload foundation
- [ ] Phase 9 — Wallet (frontend + backend cleanup)
- [ ] Phase 10 — Product search + category cleanup
- [ ] Phase 11 — Backend dead-code cleanup & conventions
- [ ] Phase 12 — Security pass (default-deny) + closing review
- [ ] Phase 13 — Final verification
