# Pre-Codex Review Handoff

**Context**: Codebase audit + refactor pass before Codex reviews Freebay against its docs. Plan lives at `C:\Users\Qiyana\.claude\plans\review-this-codebase-its-concurrent-noodle.md`. This doc captures what was done, what's left, and exactly how to resume.

---

## ✅ Done (committable)

### Phase 1 — Doc hygiene
- **Deleted** `freebay_implementation_plan.md` (stale Pagar.me-era plan).
- **`plano_c2c_hybrid_platform.md`**: added a "historical/superseded" banner at the top noting payment providers (AbacatePay + PagBank) and brand color (`#8A1083`) now diverge.
- **`AGENTS.md`**: rewrote the color table to match current theme (`#8A1083` magenta, gradient, surface hierarchy) and pointed readers at `CLAUDE.md` for the full Digital Brutalist system.
- **`CLAUDE.md`**: updated payment-provider line — AbacatePay (PIX) + PagBank (payouts), with a note that the Prisma `PaymentProvider` enum still uses legacy `PAGARME`/`WOOVI` labels.
- **`README.md`**: matching provider-note update.
- **`IMPLEMENTATION_PLAN.md`**: appended a **Known Gaps** section (Wishlist dropped, KYC stub, cloud upload partial, admin panel not started, search polish, legacy enum labels).
- **`.planning/checklist.md`**: updated header status, flagged Wishlist phases 3/7/11 as ⚫ Dropped, Phase 14 → 🟢 Complete.

### Phase 2 — Wishlist removal
Confirmed already fully removed in working tree (git `D` entries are just unstaged deletions):
- Backend: `nest-backend/src/modules/wishlist/` gone.
- Frontend: `features/wishlist/**` and `features/profile/.../wishlist_page.dart` gone.
- No stale `Wishlist` references in `prisma/schema.prisma`, `app.module.ts`, or `app_router.dart`.
- Docs updated in Phase 1.

### Phase 3 — Design-system violations
- `frontend/lib/features/auth/presentation/pages/login_page.dart:44` → `Curves.easeOutCubic` → `Curves.linear`.
- `frontend/lib/features/chat/presentation/pages/chat_list_page.dart:366-367` → duration `300 + i*50`/`easeOutCubic` → `150ms` / `Curves.linear`.
- `frontend/lib/features/product/presentation/pages/product_detail_page.dart:87` → hardcoded `Colors.black54` → `AppColors.black.withValues(alpha: 0.54)`.
- `fvm flutter analyze` → **No issues found** ✅.

### Phase 4 — Backend clean architecture
- **Split `social.repository.ts` into per-file repos** under `nest-backend/src/modules/social/repositories/`:
  `post.repository.ts`, `comment.repository.ts`, `like.repository.ts`, `share.repository.ts`, `saved-post.repository.ts`, `story.repository.ts`. `social.repository.ts` is now a barrel re-export.
- **Extended repos** with previously-missing methods:
  - `PrismaPostRepository`: `incrementLikesCount`, `decrementLikesCount`, `incrementCommentsCount` (in addition to existing `incrementSharesCount`).
  - `PrismaLikeRepository`: `findPostLike`, `deletePostLikeByUser`.
  - `PrismaStoryRepository`: `findActiveWithViews`, `upsertView`.
- **Rewrote `social.usecase.ts`** — removed **every** `PrismaService` injection from usecases; all DB access now goes through repositories. Verified by `git grep -n "PrismaService" nest-backend/src/modules/social/usecases` → 0 hits.
- **Updated `social.usecase.spec.ts`** — mocks now provide repositories (no more `PrismaService` mocking).
- **`users.controller.ts`**: removed inline `prisma.order.count` calls; `GET /users/me/stats` now delegates to `GetUserStatsUseCase`.
- **`GetUserStatsUseCase`**: no longer injects `PrismaService`; now uses `PrismaOrderRepository.countBySellerId` / `countByBuyerId` (added to `order.repository.ts`). Registered `PrismaOrderRepository` in `UsersModule`.
- **`orders/usecases/order.usecase.ts` + `order.repository.ts`**: swapped `PrismaClient` (raw type) for `PrismaService` so Nest DI tokens match the module providers. This fixed **13 pre-existing test failures** in `order.usecase.spec.ts`.
- **`user.usecase.spec.ts`** updated to mock `PrismaOrderRepository`.

### Phase 6 — Final verification
- `npx tsc --noEmit` → clean ✅
- `npm test` → **117 passed / 16 suites, 0 failures** ✅
- `fvm flutter analyze` → No issues ✅
- Guard greps all zero hits (PrismaService in social/usecases, non-zero `BorderRadius.circular`, `easeOut/easeIn` in features).

---

## ⏳ Deferred (Phase 5 — Flutter page refactor)

Three mega-pages are still oversized. Each is a mechanical widget-extraction task; I deferred them because each 700–1000 line rewrite exceeded the remaining context budget in this session. Do them one at a time — each in its own branch, each with `fvm flutter analyze` + existing widget tests green before commit.

### Target 1 — `frontend/lib/features/social/presentation/pages/feed_page.dart` (1025 lines)

**Goal**: bring page body under ~300 lines by extracting widgets.

Create these files under `frontend/lib/features/social/presentation/widgets/`:

| New widget | Extracts from feed_page.dart | Responsibility |
|---|---|---|
| `feed_header.dart` (`_FeedHeader`) | AppBar + search icon + notification bell | Pure presentation; accepts callbacks for nav. |
| `stories_row.dart` (`_StoriesRow`) | `_buildStoriesRow` method + story tile builder | Consumes `storiesProvider`, handles tap → `/stories/:userId`. |
| `social_post_list.dart` (`_PostList`) | `_buildBody` + `_buildLoadingMore` + the `ListView.builder` | Consumes feed provider, paginates on scroll. |

Also: move filter state (`Todos/Seguindo/Seguidores` chip selection) and pagination offset from the page's `StatefulWidget` into the existing feed notifier (`frontend/lib/features/social/presentation/controllers/` — check existing notifier names first; don't create a duplicate).

**Don't** change the visual output. This is a pure extraction.

### Target 2 — `frontend/lib/features/profile/presentation/pages/profile_page.dart` (839 lines)

Create under `frontend/lib/features/profile/presentation/widgets/`:

| New widget | Responsibility |
|---|---|
| `profile_header.dart` (`_ProfileHeader`) | Avatar + display name + bio + verified badge + edit button. |
| `profile_stats.dart` (`_ProfileStats`) | Posts count / followers / following / sales blocks. |
| `profile_followers_tab.dart` (`_FollowersTab`) | TabBar follower list (reuse `UserSearchList` if applicable). |

Target: page body reduces to roughly `[ProfileHeader, ProfileStats, TabBarView(children: [...])]`.

### Target 3 — `frontend/lib/core/components/social_post.dart` (714 lines)

Extract `_PostActions` subwidget (like / comment / share / save buttons + their tap handlers) into `frontend/lib/core/components/post_actions.dart`. The parent `SocialPost` keeps header + body + `PostActions(post: post, onLike: ..., onComment: ...)`. Expect to cut ~200 lines.

### Verification after each extraction
```bash
cd frontend
fvm flutter analyze          # must exit 0
fvm flutter test             # widget tests still green
```

### Stretch targets (not in original plan but flagged by audit)
If time remains after the three above, these pages are also >500 lines and worth splitting:
- `order_detail_page.dart` (683) — extract status timeline + meeting widgets.
- `create_product_page.dart` (610) — extract image picker + form sections.
- `product_detail_page.dart` (576) — extract gallery, seller card, action bar.
- `post_details_page.dart` (570) — extract comment list.
- `comments_page.dart` (508) — extract comment tile + input bar.

---

## 🧭 Starting a fresh session

Tell the fresh Claude:

> "Read `HANDOFF.md`. Resume Phase 5 (Flutter page refactor). Start with `feed_page.dart`. Work one target at a time. After each extraction run `fvm flutter analyze` and `fvm flutter test` and commit before moving to the next. Don't change visual output — pure extraction."

Environment notes the fresh session needs:
- Platform: Windows 10 / bash shell. Use forward slashes.
- Flutter: run via **`fvm flutter`** (not bare `flutter` — not on PATH).
- Backend tests: `cd nest-backend && npm test` (16 suites, 117 tests — all currently green).
- Legacy Prisma enum labels `PAGARME`/`WOOVI` actually drive AbacatePay/PagBank adapters — don't rename without a migration.

---

## 📦 Uncommitted state at handoff time

All Phase 1–4 + 6 changes are in the working tree, uncommitted. Suggested commit grouping:

```
git add README.md CLAUDE.md AGENTS.md plano_c2c_hybrid_platform.md IMPLEMENTATION_PLAN.md .planning/checklist.md
git rm freebay_implementation_plan.md
git commit -m "docs: align provider + brand color references; add known-gaps section"

git add frontend/lib/features/auth/presentation/pages/login_page.dart \
        frontend/lib/features/chat/presentation/pages/chat_list_page.dart \
        frontend/lib/features/product/presentation/pages/product_detail_page.dart
git commit -m "fix(ui): enforce 150ms linear animations + theme-aware overlay color"

git add nest-backend/src/modules/social/ nest-backend/src/modules/users/ nest-backend/src/modules/orders/
git commit -m "refactor(backend): remove PrismaService from usecases; split social repos; fix orders DI"

git rm frontend/lib/features/profile/presentation/pages/wishlist_page.dart \
       frontend/lib/features/wishlist/data/services/wishlist_service.dart \
       frontend/lib/features/wishlist/presentation/providers/wishlist_provider.dart \
       nest-backend/src/modules/wishlist/repositories/wishlist.repository.ts \
       nest-backend/src/modules/wishlist/wishlist.controller.ts \
       nest-backend/src/modules/wishlist/wishlist.module.ts
git commit -m "chore: finalize wishlist removal (superseded by favorites)"
```

The other modified files in `git status` (frontend pages, auth repos, etc.) appear to be pre-existing work from before this session — inspect each before including.
