# Freebay — Production Hardening & Missing Features

> **Execution mode:** Manual (direct) execution by the controlling agent, not full subagent-driven-development — phases are tightly sequential (schema → feed/username → search/suggestions → chat/upload → wallet → cleanup → security), so a fresh-subagent-per-task loop would constantly re-derive context. Progress tracked in `.superpowers/sdd/progress.md`. Final broad review still happens at the end (Phase 12/13).
>
> **Branch:** `feat/production-hardening` (created from `master`).
>
> **Pacing:** run phases back-to-back; defer the full test/analyze suite to Phase 13. Run targeted `tsc`/single-spec checks only where a phase's correctness is non-obvious. Commit per logical unit within a phase, not one giant commit per phase.

## Context

Freebay is a full-stack C2C marketplace (NestJS + Prisma/Postgres backend, Flutter/Riverpod frontend) that is feature-rich but not production-finished. Recon across the whole codebase found the core code is clean (no Fastify leftovers, no stray `console`/`print`, no `@ts-ignore`, one real stub), but several headline features are half-wired: the feed has ranking but no pagination and no full-page scroll, friend suggestions exist end-to-end on the backend yet are surfaced nowhere on the profile, order chat is effectively non-functional, the wallet page shows a balance but no withdraw/history, product & user search are shallow, and the `UsersController` inlines logic while leaving 9 use cases as dead code (the live follow endpoint even skips its notification). Auth is opt-in per route (default-open) rather than default-deny.

This plan takes the app to a production-ready state across the exact surfaces the user named — **feed algorithm, profile friend-suggestions, chat, wallet, product/category search, user search** — plus a general code cleanup and a closing security pass. It reuses four in-repo plans that already spec parts of this work: `docs/superpowers/plans/2026-07-11-{bug-fixes,chat-premium,post-mentions,shared-upload}.md` (several bug-fix tasks — color picker, 413 body limit, FK indexes, explorar collapsible bar — already landed in recent commits).

## Design decisions (from the interview)

1. **Username:** add a real unique `@username`, **required at signup** (with a live availability check), and **backfill all existing users** in the migration. Editable later in profile.
2. **Feed:** keep two feeds — ranked **"Para você"** (engagement + recency decay + affinity to who you follow) and chronological **"Seguindo"** — both with real infinite-scroll pagination, block-filtering, and the full-page-scroll fix.
3. **People search:** move it **out of Explorar into its own dedicated screen/entry**; Explorar becomes products-only.
4. **Order chat:** make it **fully functional** (fetch/send/react on order threads via the existing `ChatThreadAccessService`) **plus Instagram-style swipe-to-reply** — the replied-to message shows above the input and the current draft is **not** cleared.
5. **Wallet:** wire **PIX withdraw + transaction/withdrawal history**; PagBank bank-account registration stays a documented stub.
6. **Security:** flip to a **default-deny global JWT guard** with explicit `@Public()`.

## Execution notes

- After any `@JsonSerializable`/`@freezed` change: `cd frontend && fvm flutter pub run build_runner build --delete-conflicting-outputs`.
- Zero-issue `fvm flutter analyze` and clean `npx tsc --noEmit` are the bar. Flutter is via `fvm`.
- No new code comments (project rule); fix root causes, don't loosen validators.

---

## Phase 1 — Schema & data foundations (Prisma)

Files: `nest-backend/prisma/schema.prisma`, new migration(s).

- **`User.username`** — add `username String @unique` (stored lowercased). Backfill in the migration via raw SQL: slugify `displayName` (`lower`, strip non-`[a-z0-9_]`, collapse), dedupe with a `row_number()` suffix, fallback `user_<id-fragment>` for empty slugs. Two-step in one migration: add nullable → backfill → set `NOT NULL`.
- **`WithdrawalStatus` enum** (`PENDING|PROCESSING|COMPLETED|FAILED`) — migrate `Withdrawal.status String` → enum.
- **`Report.reportedPostId`** — add `@@index`.
- Confirm (recon) that chat premium schema is already present — `MessageReaction`, `DirectMessage.replyToId/deletedAt/reactions`, `ChatMessage` parity, `User.lastSeenAt` all exist; **no migration needed there**.
- `npm run prisma:migrate` (name: `username_withdrawal_enum_report_index`) + `npm run prisma:generate`.

## Phase 2 — Feed algorithm (backend)

Files: `social/data/repositories/post-database.repository.ts` (`findFeed`), `social/domain/repositories/post.repository.ts` (`FeedQuery`), `social/usecases/get-feed.usecase.ts`, `social/dtos/social.dto.ts` (`GetFeedQueryDTO`), `social/social.controller.ts`.

- Rework `findFeed` into two paginated modes:
  - **`following`** — keyset paginate by `(createdAt, id)` desc over `userId IN (followingIds)`, excluding authors the viewer blocked or is blocked by. Returns `nextCursor` + `hasMore`.
  - **`explore` ("Para você")** — ranked. Score candidates (recent window, exclude blocked + own optional) as `engagement * exp(-ageHours/48) * affinityBoost` where `affinityBoost` lifts posts by followed users; paginate with `offset`/page and return `hasMore`. Removes the current `limit*3`-window-only limitation by widening the candidate set.
- Add server-side **content filter** (`all|social|selling` → `Post.type` mapping) to `FeedQuery`/DTO so filtering paginates correctly (today it's a client-only filter that breaks paging).
- Add `cursor`/`offset` + `contentFilter` to `GetFeedQueryDTO`; controller + usecase pass through.

## Phase 3 — Feed frontend + full-page scroll

Files: `social/presentation/providers/feed_provider.dart`, `social/presentation/pages/feed_page.dart`, `social/presentation/widgets/feed_filters.dart`, coordinate with `core/components/{app_shell,hide_on_scroll,page_header}.dart`.

- `feed_provider.dart`: honor backend cursor/offset, stop duplicate-append, add real `loadMore`.
- `feed_page.dart`: add infinite-scroll trigger (scroll-end → `loadFeed(refresh:false)`); pass `contentFilter` to the backend instead of filtering client-side.
- **Full-page scroll (user ask):** feed content must fill the whole screen and scroll under the header/navbar — hook the feed header into the existing `HideOnScrollController`/`ScrollAwareBar` pattern (already used for the bottom nav in `app_shell.dart`), remove the black header-bar background so nothing gets cut off on scroll (bug-fixes Task 1).

## Phase 4 — Username (backend + frontend)

Backend: `auth/dtos/auth.dto.ts` (`RegisterDTO` + `UpdateProfileDTO`), `auth/usecases/register.usecase.ts`, `auth/domain/repositories/user.repository.ts` + impl (`findByUsername`), `auth/mappers/auth.mapper.ts` + `users/mappers/user.mapper.ts` (expose `username`), a `GET /auth/username-available?u=` endpoint.
- Validate username: 3–20 chars, `^[a-z0-9_]+$`, lowercased; uniqueness checked in register + update.

Frontend: registration page adds a username field with debounced availability check; `edit_profile_page.dart` adds editable username; render `@username` on profile header, user cards, and search results. Re-run codegen for updated user entities.

## Phase 5 — User search + dedicated people-search screen

Backend: `auth/data/repositories/user-database.repository.ts` `searchUsers` — match `username` (prefix-priority) + `displayName` (contains), case-insensitive; deterministic ordering (exact/prefix first, then `followersCount` desc, `id` tiebreaker for stable cursoring); exclude blocked when authenticated.

Frontend: new dedicated **people-search page + route + entry point** (search icon in feed header / discovery entry); remove the "Pessoas" tab from `explorar_page.dart` (Explorar → products-only, single product search field). Fix the follow-button state bug in `social/presentation/widgets/user_search_list.dart` — seed `_isFollowing` from server and drive it via a provider + `invalidate` (the pattern already correct in `user_profile_page.dart`). Reuse `UserSearchList`, `userSearchProvider`.

## Phase 6 — Profile friend suggestions

Backend: `auth/data/repositories/user-database.repository.ts` `getSuggestions` — exclude blocked, **rank by `mutualCount` desc**, fallback to popular users (by `followersCount`) when the viewer follows nobody. Route it through the restored `GetSuggestionsUseCase` (Phase 11).

Frontend: wire the currently-dead `suggestionsProvider`/`SuggestionsNotifier` (in `social/presentation/providers/user_search_provider.dart`) into a **"Quem seguir" section on the own profile** (`profile/presentation/pages/profile_page.dart`) and into the new people-search empty state. Reuse `UserSearchList`/a horizontal suggestion card.

## Phase 7 — Chat: unify order+direct, replies, reactions, polish

Backend (`modules/chat/`):
- Make **order chat functional**: `GetMessagesUseCase`, `SendMessageUseCase`, `DeleteMessageUseCase`, `ToggleReactionUseCase` resolve the thread via `ChatThreadAccessService.resolveThread` and operate on `ChatMessage` for order threads (stop hardcoding `'DIRECT'` in controller/gateway). Include order `ChatMessage` preview + unread in the unified list (`findOrdersByUser` include last message).
- `GetMessagesUseCase` returns the **`preference`** (theme/background), `threadType`, `otherUserId`, and **hydrates `replyTo`/`replyToId`** so themes and replies render on open (today `preference`/replies are never returned).
- Remove the dead `/read` mismatch (read is already written inside `GetMessagesUseCase`) — drop the frontend `markAsRead` call.

Frontend (`features/chat/`):
- **Real reply threading + Instagram swipe-to-reply**: swiping a message sets a reply target shown as a banner **above the input without clearing the current draft**; send `replyToId`; render `replyTo` preview in bubbles; tap-to-scroll to original (`reply_preview_banner.dart`, `message_bubble.dart`, `chat_conversation_page.dart`).
- **Optimistic reactions** (no full `_loadMessages()` reload); apply `preference` theme/background on initial load.
- Fix `new_chat_page.dart` typo `oderName`/`oderAvatarUrl` → `orderName`/`orderAvatarUrl` (blank new-chat header).
- Verify the chat list renders (recon shows the earlier "no conversations" bug appears already fixed — providers non-autoDispose, keepAlive mixin, correct JSON path); center the conversation empty state.

## Phase 8 — Shared upload foundation (production image handling)

Implement `POST /uploads` (multer disk storage) + `ServeStaticModule` + Flutter `UploadService` per `docs/superpowers/plans/2026-07-11-shared-upload.md`. Migrate chat background, **chat image messages**, and avatar/banner off base64 data URIs to uploaded relative URLs — this removes DB bloat and is the real fix behind the 413 chat-background error. (Do the backend upload endpoint before the Phase 7 chat-image frontend so images have somewhere to go.)

## Phase 9 — Wallet (frontend feature + backend cleanup)

Frontend (`features/wallet/`): replace the hardcoded empty history with the real transaction list (the `getTransactions` path already exists end-to-end, just unused); build the **withdraw flow** — amount input (min R$20, ≤ available), client-generated idempotency key, confirm → `POST /wallet/withdraw`, success/error snackbars, balance refresh; show the **withdrawals list** (`GET /wallet/withdrawals`). Reuse `WalletCard`, `WalletSkeleton`. (Withdraw is amount-only for now — destination comes with PagBank later.)

Backend: consolidate the pending→available escrow-release logic (duplicated across `confirmDelivery`, `escrow-release.task`, `dispute-resolution-execution.service`, `cancelOrder`) into one `WalletRepository.releaseEscrow`/`creditAvailable`. Fix the wallet-nav bug (tapping Carteira from feed keeps Freebay tab active — use `goBranch`/`context.go`; bug-fixes Task 2).

## Phase 10 — Product search + category cleanup

Backend products (`products/data/repositories/product-database.repository.ts`, `products/dtos/product.dto.ts`): search `title` **+ `description`** (insensitive); add a **`condition`** filter; add **sort options** (recent, price asc/desc, popular by `soldCount`); expand a category filter to its **descendants**; make the cursor consistent with the chosen sort (tiebreak on `id`).

Category (`modules/category/`): fix `findAll` to return the full tree (or cap intentionally) so it matches the frontend's N-level flattener; normalize the concrete repo's `PrismaClient` token → `PrismaService` (convention); add per-category product counts / hide empty categories; wire `slug` or remove it.

Frontend Explorar (`product/presentation/pages/explorar_page.dart`, `category_filter_panel.dart`, `product_controller.dart`): products-only now; add price-range + sort UI; wire **infinite scroll** (repo already supports cursor + price); make `productsFeedProvider` **non-autoDispose** (shell-tab rule).

## Phase 11 — Backend dead-code cleanup & conventions

- Refactor `users/users.controller.ts` to **delegate to the existing use cases** (`FollowUserUseCase` — restores the missing new-follower notification; `UnfollowUserUseCase`, `SearchUsersUseCase`, `GetSuggestionsUseCase`, `BlockUserUseCase`, `UnblockUserUseCase`, `GetProfileUseCase`, `UpdateProfileUseCase`, `UpdateFcmTokenUseCase`) — one source of truth, delete the inlined logic, keep DTO/mapper response shapes.
- Add `@SanitizeText()` to remaining free-text DTOs missing it (chat messages, reviews, reports).
- Remove/rewire any remaining dead providers surfaced during the work.

## Phase 12 — Security pass (default-deny) + closing review

- **Flip to default-deny:** register global `JwtAuthGuard` as `APP_GUARD` in `app.module.ts`; annotate genuinely public routes with `@Public()` — audit every currently-public route (`GET /products`, `/products/:id`, `/categories`, `/users/:id`, followers/following, `/users/search`) and decide guarded-vs-public (guests carry a token, so most stay guarded). Ensure `JwtAuthGuard` honors `@Public()` + token-type metadata.
- Fix `auth.controller.ts` direct `process.env.JWT_SECRET` → `ConfigService.getOrThrow`.
- Align the upload size mismatch (`products.controller` 1MB vs 5MB util).
- `storage_service.dart` `clearTokens()` — clear `remember_me` on logout, intentionally preserve `has_seen_onboarding`.
- Parameterize base URL/HTTPS for prod (the hardcoded Android LAN IP + plain HTTP is a dev default via `app_config.dart`; keep `--dart-define` override, document prod).
- **Closing security review:** run the `security-auditor` agent over the branch diff and address findings; then prompt the user to run **`/grill-with-docs`** (it's user-invoke-only) for the doc-driven security interview per the original goal.

## Phase 13 — Final verification

- Backend: `cd nest-backend && npx tsc --noEmit && npm test` (+ `npm run test:integration` if DB/Redis up).
- Frontend: `cd frontend && fvm flutter pub run build_runner build --delete-conflicting-outputs` (after entity changes), then `fvm flutter analyze` (zero issues) and `fvm flutter test`.
- Smoke the key flows via `/run`: register-with-username, feed scroll + infinite load + full-page, people search, profile suggestions + follow/unfollow re-follow, order + direct chat send/reply/react, wallet withdraw + history, product search filters/sort.
- Update `TODO.md` checkboxes and `CLAUDE.md` (the guard section now describes a real global default-deny guard).

## Verification (how to know it's done)

- `npx tsc --noEmit` clean; `npm test` green; `fvm flutter analyze` zero issues; `fvm flutter test` green.
- Feed pages deeper than 20 posts without duplicates and fills the screen edge-to-edge on scroll.
- Following a user sends a notification; unfollow → re-follow works from every surface.
- `@username` is required at signup, unique, backfilled, searchable; people-search lives on its own screen.
- Profile shows friend-of-friend suggestions ranked by mutuals.
- Order chat and direct chat both fetch/send/react; swipe-to-reply keeps the draft.
- Wallet lists transactions + withdrawals and completes a PIX withdraw.
- Product search matches title+description with condition/price/sort filters and paginates.
- A default-deny global guard is in place with audited `@Public()` routes; `security-auditor` findings resolved.
