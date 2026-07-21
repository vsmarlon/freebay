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
- [~] Phase 5 — User search + dedicated people-search screen. BACKEND DONE + verified (tsc clean, npx jest src/modules/users src/modules/auth: 59/59 green, raw-SQL ranked search manually verified against dev DB — exact/prefix username match ranks first, then followersCount desc, block-exclusion works). FRONTEND PARTIAL — see "Resume here" below.

  **Backend changes (committed as part of this phase, not yet git-committed as of interruption):**
  - `user-search.types.ts`: `UserSearchResult`/`UserSuggestionResult` now have `username: string`; `UserSearchResult` flattened `_count:{followers,following}` → `followersCount`/`followingCount` (matches raw SQL alias shape).
  - `user.repository.ts` (domain): `searchUsers(query, limit, cursor?)` → `searchUsers(query, limit, offset, viewerId?)`.
  - `user-database.repository.ts`: `searchUsers` rewritten with `$queryRaw`/`Prisma.sql` (needed CASE-based rank ordering Prisma's fluent API can't express) — exact username match rank 0, prefix match rank 1, contains rank 2, then followersCount DESC, id ASC tiebreak. Block-exclusion via `NOT EXISTS` on `Block` table when `viewerId` present. `getSuggestions` select/mapping also gained `username` (Phase 6 will do the real mutualCount-ranking rework, this was just to keep the type consistent).
  - `dtos/user.dto.ts`: `UserSearchQueryDTO.cursor` → `offset` (mirrors `OffsetPaginationQueryDTO`); `SearchUsersInput` gained `offset`/`viewerId`.
  - `mappers/user.mapper.ts`: `SearchUserResponse`/`SuggestionResponse` gained `username`.
  - `usecases/search-users.usecase.ts`, `usecases/get-suggestions.usecase.ts`: updated to new signatures/username (these two usecases are still NOT wired into `users.controller.ts` — that's Phase 11's job, controller still inlines the logic directly).
  - `users.controller.ts`: `GET /users/search` handler now takes `@CurrentUser() user: AuthUser` (route has no guard, so `user` is `undefined` when unauthenticated — matches the `social.controller.ts` feed pattern), passes `user?.userId` as viewerId, returns `{users, hasMore, nextOffset}` instead of `{users, nextCursor}`. `GET /users/suggestions` mapping also includes `username` now.
  - `usecases/user.usecase.spec.ts`: mock data updated for new shapes.

  **Frontend changes so far (flutter analyze: 0 issues, confirmed. One bug was caught+fixed along the way: removing `followServiceProvider`/`followStatusProvider` from `user_profile_page.dart` also removed its `follow_responses.dart` import, which that file still needed for the bare `FollowStatusResponse` type name at a `ref.watch(followStatusProvider(user.id))` call site — fixed by re-adding `import 'package:freebay/features/profile/data/entities/follow_responses.dart';`.):**
  - New `data/entities/user_search_page_result.dart` (`UserSearchPageResult{users,hasMore,nextOffset}`), mirrors `FeedPageResult` from Phase 3.
  - `i_social_repository.dart` + `social_repository.dart`: `searchUsers` now returns `Either<Failure, UserSearchPageResult>` and takes `offset` instead of `cursor`.
  - `user_search_provider.dart` (`UserSearchNotifier`/`UserSearchState`): switched from cursor to offset tracking, same pattern as `FeedNotifier` (Phase 3) — `if (!refresh && !state.hasMore) return;` guard added too.
  - New `features/profile/presentation/providers/follow_status_provider.dart` — extracted `followServiceProvider`/`followStatusProvider` out of `user_profile_page.dart` (which now imports them) so they're reusable.
  - `user_search_list.dart`: `_UserSearchItem` converted `StatefulWidget` → `ConsumerStatefulWidget`, now seeds `isFollowing` from `followStatusProvider(user.id)` instead of a hardcoded `false`, invalidates that provider after a successful follow/unfollow (this was the explicit "fix the follow-button state bug" plan item). Also now hides the Follow button entirely when the card is the viewer's own profile.

  **Resume here — remaining Phase 5 work, in order (flutter analyze 0 issues already confirmed, backend already committed-worthy — just go straight to step 1):**
  1. Create the dedicated people-search page: `frontend/lib/features/social/presentation/pages/people_search_page.dart`. Model it on `post_search_page.dart` (`PageHeader` + search `AppTextField` w/ 300ms debounce, same pattern as `explorar_page.dart`'s old `_buildPessoasTab`) but reuse `UserSearchList` + `userSearchProvider` (already offset-paginated, already fixed). Empty state before typing: reuse the "Busque por pessoas..." placeholder currently in `explorar_page.dart._buildPessoasTab`.
  3. Add route: `AppRoutes.peopleSearch = '/people/search'` in `app_routes.dart`, register a plain `GoRoute` in `app_router.dart` (see how `AppRoutes.postSearch` is registered ~line 238 for the pattern — note `postSearch` is itself a dead/unreachable route today, don't copy that mistake, this one needs a real entry point).
  4. Wire an entry point per plan: add a search icon to `feed_page.dart`'s header `actions` (alongside the existing notifications/wallet `_HeaderIcon`s) that does `context.push(AppRoutes.peopleSearch)`.
  5. Remove the "Pessoas" tab from `explorar_page.dart`: drop `TabController`/`TabBar`/`TabBarView` entirely (or set `length: 1`), delete `_buildPessoasTab`, the `userSearchProvider`/`UserSearchList` imports, `_followingMap` field (dead once the tab's gone — note `user_search_list.dart` no longer needs an external `_followingMap` since it now self-manages via `followStatusProvider`), and simplify the search bar hint back to always 'Buscar produtos...'.
  6. `flutter analyze` zero issues, `npx tsc --noEmit` clean (already was), commit as `feat(social): user search + dedicated people-search screen`.
  7. Update this ledger to `[x] Phase 5` and move to Phase 6.
- [ ] Phase 6 — Profile friend suggestions
- [ ] Phase 7 — Chat: unify order+direct, replies, reactions, polish
- [ ] Phase 8 — Shared upload foundation
- [ ] Phase 9 — Wallet (frontend + backend cleanup)
- [ ] Phase 10 — Product search + category cleanup
- [ ] Phase 11 — Backend dead-code cleanup & conventions
- [ ] Phase 12 — Security pass (default-deny) + closing review
- [ ] Phase 13 — Final verification
