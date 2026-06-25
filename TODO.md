# Freebay TODO — Iterable Polish Backlog

> Living document. Check items off as they land. Add new items as they're discovered.
> Severity: `[CRIT]` = blocking, `[HIGH]` = important, `[MED]` = nice to have, `[LOW]` = eventual.

---

## Backend

### God-file usecase splits `[HIGH]`
- [x] Split `modules/social/usecases/social.usecase.ts` — 9 classes → `create-post`, `like-post`, `unlike-post`, `comment`, `create-story`, `get-stories`, `get-user-stories`, `view-story`, `delete-story`
- [x] Split `modules/chat/usecases/chat.usecase.ts` — 5 classes → `send-message`, `get-conversations`, `get-messages`, `start-conversation`, `accept-conversation`
- [x] Split `modules/disputes/usecases/dispute.usecase.ts` — 5 classes → `open-dispute`, `get-dispute`, `get-user-disputes`, `submit-evidence`, `resolve-dispute`
- [x] Split `modules/reports/usecases/report.usecase.ts` — 3 classes → `create-report`, `get-reports`, `resolve-report`

### Either anti-pattern fixes `[HIGH]`
- [x] `modules/cart/cart.controller.ts` — all business errors now use `left()` instead of `throw`
- [x] `modules/cart/usecases/checkout-cart.usecase.ts` — pre-check availability instead of `throw` inside transaction
- [x] `modules/social/social.controller.ts` — `createStory` uses `left()` instead of `throw BadRequestException`

### Missing specs `[HIGH]`
- [ ] Add controller specs (0 of 15 controllers have tests)
- [ ] Add usecase specs for: `cart`, `category`, `chat`, `favorites`, `reports`, `tasks`, `repositories`
- [ ] Add integration specs for key flows (auth, orders, payments, escrow)

### Docs
- [ ] Add `nest-backend/README.md` with setup, architecture, and dev workflow

---

## Frontend

### Design-system violations `[MED]`
- [ ] `core/router/app_router.dart` — page transitions use 250–300ms + `easeInCubic`/`easeOutCubic`; should be 150ms `Curves.linear`
- [ ] `social_post.dart` — price tag uses `primaryContainer` instead of `surface_container_highest`
- [ ] Audit all pages for hardcoded `Colors.white` / `Colors.black` instead of `context.isDark` / theme extension
- [ ] Audit all pages for `BorderRadius.circular()` > 0

### Docs
- [ ] Replace stale `frontend/README.md` (stock Flutter boilerplate) with project-specific README

---

## Database (Prisma)

### Enum migrations `[HIGH]`
- [ ] `Withdrawal.status` — currently bare `String`; migrate to `WithdrawalStatus` enum
- [ ] `DirectConversation.status` — currently bare `String`; migrate to `ConversationStatus` enum

### Missing `onDelete` constraints `[MED]`
- [ ] `Order → Product` — missing `onDelete`
- [ ] `Dispute → Order` — missing `onDelete`
- [ ] `Category` self-reference — missing `onDelete`
- [ ] `Comment → User` — missing `onDelete`
- [ ] `CommentLike → User` — missing `onDelete`

### Missing indexes `[MED]`
- [ ] `Report.reportedUserId`
- [ ] `Report.postId`
- [ ] `DirectMessage.senderId`
- [ ] Review other FK columns for missing indexes

### Schema drift
- [ ] Capture base schema as a migration (only `PasswordRecoveryCode` migration exists — if the schema is recreated from scratch it won't match)
- [ ] `@db.VarChar` caps on free-text columns (e.g. `bio`, `description`)

### Model gaps
- [ ] Link `Withdrawal` → `Transaction` / `Order` (currently independent)

---

## Docs

### Setup & contribution
- [ ] Create `frontend/.env.example` + setup guide in frontend README
- [ ] Create `CONTRIBUTING.md` — branch naming, commit style, PR workflow
- [ ] Architecture/escrow flow diagram (or ADR) for the payment lifecycle

### Conventions
- [ ] Align `AGENTS.md` — ensure it says **class-validator** (not Zod) for DTO validation

---

## Testing & CI

### Backend
- [ ] `[HIGH]` Expand specs for untested modules: cart, category, chat, favorites, reports, tasks, repositories
- [ ] `[MED]` Set coverage thresholds in jest config
- [ ] `[MED]` Remove `console.*` warnings from `main.ts` (use `Logger` instead)

### Frontend
- [ ] `[HIGH]` Add real widget/provider tests for key features: auth, product, orders, profile (currently ~2%)
- [ ] `[MED]` Set up coverage reporting

### CI/CD
- [x] Fix 6 backend ESLint errors (unused imports/params)
- [x] Fix frontend analyze warning (unused import in `profile_tabs.dart`)
- [x] Enhance `ci.yml` — add lint/tsc/integration jobs
- [x] Add Husky pre-commit hooks
- [ ] `[LOW]` Add Docker/container build step to CI
- [ ] `[LOW]` Set up deployment pipeline

---

## Round-3 Bugs `[CRIT]`

### Fixes applied (pending manual verification — do not mark complete)

- [ ] **Sidebar swipe** → `frontend/lib/features/social/presentation/pages/feed_page.dart` — set `drawerEnableOpenDragGesture: false` (was `true`), deleted stale comments in `feed_page.dart` and `app_shell.dart`
- [ ] **Conversations not updating** → Added real-time Socket.IO client:
  - Added `socket_io_client: ^3.0.2` to `pubspec.yaml`
  - New `frontend/lib/shared/services/chat_socket_service.dart` — connects to backend `/chat` namespace, joins/leaves rooms, sends messages, broadcasts `messageStream`
  - New `frontend/lib/features/chat/presentation/providers/chat_socket_provider.dart` — service lifecycle provider
  - New `ChatListController` (`chat_provider.dart:75-119`) — `StateNotifier` seeded from `chatsProvider`, patches list on socket `new_message` events; exposed as `liveChatListProvider`
  - `chat_conversation_page.dart` — joins room on load, listens for incoming messages (deduped by `msg['id']`), sends via socket (REST fallback)
  - `chat_list_page.dart` — switched from `chatsProvider` to `liveChatListProvider`
  - `app_shell.dart` — added `WidgetsBindingObserver`, connects/disconnects socket based on `authControllerProvider`, reconnects on app resume
- [ ] **Date crash** → `chat_conversation_page.dart:533` — guard `DateTime.parse` with `msg['createdAt'] is String`; same fix in `chat_entity.dart:45-48`
- [ ] **Wallet loading/design** →
  - New `frontend/lib/core/components/shimmer_skeleton.dart` — `ShimmerBlock` and `WalletSkeleton` static tonal blocks
  - `wallet_page.dart` — replaced `CircularProgressIndicator` with `WalletSkeleton`, wrapped "Visão da carteira" in `SectionTitle`, applied surface-hierarchy colors, collapsed duplicate `if (isGuest) ... else ...` into single call
- [ ] **Post like/repost spinner** → `post_details_page.dart:234-300` — removed all three `.refresh()` calls after `toggleLike`, `toggleRepost`, and `sharePost` (override providers already keep state in sync)
- [ ] **Theme toggle** → `profile_settings_sheet.dart:51-67` — replaced `PopupMenuButton<ThemeMode>` with inline `Row` of three `_ThemeOption` buttons (S/L/D) to avoid stale overlay snapshot
- [ ] **Biometry config** →
  - `MainActivity.kt` — changed `FlutterActivity` to `FlutterFragmentActivity`
  - `AndroidManifest.xml` — added `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`
  - `Info.plist` — added `NSFaceIDUsageDescription` string
- [ ] **Explore/Following dropdown dark mode** → verified: `FeedTypeDropdown` already uses `context.textPrimary` (dark-mode aware), `context.surfaceColor` (dark-mode aware), and explicit `AppColors` for active state — no changes needed

## Chat Features `[HIGH]`

- [ ] **Archive chats** — archive a conversation, view archived list, unarchive
- [ ] **Block users from chat** — block/unblock from chat header 3-dot menu
- [ ] **Report from chat** — report a conversation or specific message
- [ ] **Chat config (3-dot menu)** — per-conversation settings drawer
- [ ] **Custom chat themes** — selectable color themes per conversation
- [ ] **Custom chat backgrounds** — user can upload/select an image as background per chat
- [ ] **Delete conversations** — soft-delete a conversation from chat list
- [ ] **Search chats** — filter conversations by name or message content

---

## Skeleton Loading Rollout `[done]`

> Replaced all 58 `CircularProgressIndicator` sites with bespoke animated shimmer skeletons. ShimmerBlock has animated sweep effect. AppButton shows shimmer on load. order_actions.dart refactored to use AppButton. All 0 CircularProgressIndicator remain in lib/.

### Shared Primitives

- [x] **`shimmer_skeleton.dart`** — Animated sweep effect on `ShimmerBlock`, added `SkeletonList`, `SkeletonPage`, kept `WalletSkeleton`.
- [x] **`app_button.dart`** — `CircularProgressIndicator` → shimmering `ShimmerBlock`.
- [x] **`order_actions.dart`** — Refactored to use `AppButton` (eliminated 2 inline spinners).
- [x] **`comment_input.dart`** — Send-button spinner → `ShimmerBlock`.

### Group A — Social (12 files) `[done]`

- [x] **`feed_page.dart`** — Load-more → feed-post skeleton row.
- [x] **`post_details_page.dart`** — Full-page → post skeleton (avatar, image, actions, comments).
- [x] **`post_search_page.dart`** — Inline → search-result row skeleton.
- [x] **`story_viewer_page.dart`** — Image-loading → dark tonal block.
- [x] **`story_viewer_wrapper.dart`** — Full-page → story skeleton.
- [x] **`my_posts_page.dart`** — Full-page → `AppCard.skeleton()` grid.
- [x] **`my_stories_page.dart`** — Inline → horizontal story ring skeleton.
- [x] **`liked_posts_page.dart`** — Full-page → grid skeleton.
- [x] **`comments_page.dart`** — Full-page → comment thread skeleton; send/reply buttons → shimmer blocks.
- [x] **`comment_bottom_sheet.dart`** — Send-button → shimmer block.
- [x] **`user_search_list.dart`** — Load-more → user-row skeleton; follow button → shimmer block.

### Group B — Product/Shopping (7 files) `[done]`

- [x] **`product_list_page.dart`** — Full-page → `AppCard.skeleton()` grid.
- [x] **`explorar_page.dart`** — Full-page → `AppCard.skeleton()` grid.
- [x] **`cart_page.dart`** — Full-page → cart row skeleton.
- [x] **`cart_checkout_page.dart`** — Full-page → checkout summary skeleton.
- [x] **`create_product_page.dart`** — Covered by `AppButton` shimmer.
- [x] **`edit_product_page.dart`** — Full-page → form skeleton.
- [x] **`my_products_page.dart`** — Full-page → `AppCard.skeleton()` grid.

### Group C — Orders/Disputes (5 files) `[done]`

- [x] **`order_detail_page.dart`** — Full-page → order detail skeleton; image placeholder → shimmer block.
- [x] **`dispute_list_page.dart`** — Full-page → `SkeletonList` of dispute rows.
- [x] **`dispute_detail_page.dart`** — Full-page → dispute skeleton (status, description, timeline).
- [x] **`create_dispute_page.dart`** — Covered by `AppButton` shimmer.

### Group D — Chat (4 files) `[done]`

- [x] **`chat_conversation_page.dart`** — Full-page → message bubbles skeleton (alternating sent/received).
- [x] **`chat_conversation_page.dart:605`** — Covered by `AppButton` shimmer.
- [x] **`archived_chats_page.dart`** — Full-page → chat row skeleton.
- [x] **`new_chat_page.dart`** — Spinners → user search row skeleton.

### Group E — Profile (10 files) `[done]`

- [x] **`profile_page.dart`** — Full-page → profile skeleton (avatar, stats, tabs, post grid).
- [x] **`user_profile_page.dart`** — Full-page → profile skeleton.
- [x] **`followers_page.dart`** — Full-page → `SkeletonList` of follower rows.
- [x] **`following_page.dart`** — Same as followers skeleton.
- [x] **`blocked_users_page.dart`** — Inline → shimmer block.
- [x] **`purchases_page.dart`** — Full-page + load-more → `SkeletonList` of purchase rows.
- [x] **`edit_profile_page.dart`** — Avatar upload → shimmer block; save button → `AppButton` shimmer.
- [x] **`payment_page.dart`** — Full-page → payment skeleton; button → `AppButton` shimmer.
- [x] **`profile_tabs.dart`** — Inline tab → grid skeleton.

### Group F — Reviews (2 files) `[done]`

- [x] **`user_reviews_page.dart`** — Full-page + load-more → review row skeleton.
- [x] **`create_review_page.dart`** — Covered by `AppButton` shimmer.

### Group G — Notifications (1 file) `[done]`

- [x] **`notifications_page.dart`** — Full-page → notification row skeleton.

### Group H — Remaining inline spinners `[done]`

- [x] **`create_post_page.dart:123`** — Covered by `AppButton` shimmer.
- [x] **`create_story_page.dart:190,283`** — Covered by `AppButton` shimmer.

### Verification

- [x] **`flutter analyze`** — 0 errors, 0 warnings from this work (3 pre-existing warnings untouched).
- [x] **`flutter test`** — All tests pass.
- [ ] **Manual spot-check** — followers list, order detail, product grid, chat conversation, button save action (light + dark mode)

---

## Skeleton/Header/Auth Regressions `[CRIT]`

### Fixed in this pass

- [x] `[CRIT]` `new_chat_page.dart` — clear `_isLoadingFollowing` / `_isLoadingSuggestions` in all auth/error paths; avoid permanent skeleton after expired token.
- [x] `[CRIT]` `shimmer_skeleton.dart` — `SkeletonList` now has `shrinkWrap: true` to avoid unbounded ListView inside `SkeletonPage`.
- [x] `[HIGH]` `auth_controller.dart` / `main.dart` — added `forceLogout()` method, wired through `HttpClient.onAuthLost`.
- [x] `[HIGH]` `chat_socket_service.dart` / `app_shell.dart` — handle WebSocket auth `connect_error` (JWT rejection), stop reconnecting with expired token; app resume only reconnects if still authenticated.
- [x] `[HIGH]` `app_router.dart` — added auth-aware redirect via `refreshListenable` + `redirect` callback; protected routes redirect to `/login` when not authenticated.
- [x] `[HIGH]` `page_header.dart` — normalized row height to 48px, constrained leading/action slots to 40×40 so `MENSAGENS`, `CARTEIRA`, `FREEBAY!`, `PERFIL` align while swiping.
- [x] `[MED]` `app_shell.dart` — changed nav labels to Portuguese: `FREEBAY!`, `EXPLORAR`, `CARTEIRA`, `MENSAGENS`, `PERFIL`.
- [x] `[MED]` `guest_profile_view.dart` — replaced Material `AppBar` with shared `PageHeader` for visual consistency.
- [x] `[MED]` `section_title.dart` / `wallet_page.dart` — added `SectionTitle.compact` variant (18px), used for "Visão da carteira".
- [x] `[MED]` `chat_list_page.dart` — fixed `/new-chat` route to `/chat/new`.
- [x] `[MED]` `archived_chats_page.dart` — removed invalid nested `Expanded` around empty state.

### Verification

- [x] `flutter analyze` — 0 errors from this work (3 pre-existing warnings, 25 info-level lints untouched).
- [x] `flutter test` — All tests pass.
- [ ] Manual spot-check each group: Nova Conversa (auth loss), Perfil (guest + auth), Mensagens, Carteira (wallet loading), Freebay! (feed skeleton), button save action — light + dark mode.

---

## Done (this pass)

- [x] Improved `CLAUDE.md` — controller response-shaping, one-class-per-usecase, WS/chat, routing guards, mapper pattern, seeds, integration tests, throttler, Swagger
- [x] Extended `freebay-design-system` skill — component catalog, dark-mode rules, price/anim rules
- [x] Created `freebay-backend-module` skill (`.claude/skills/`)
- [x] Created `freebay-flutter-feature` skill (`.claude/skills/`)
- [x] Created `freebay-data-model` skill (`.claude/skills/`)
- [x] Fixed backend ESLint (6 errors)
- [x] Fixed frontend analyze (1 warning)
- [x] Enhanced ci.yml (lint/tsc/integration jobs)
- [x] Added Husky pre-commit hooks
