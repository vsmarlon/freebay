# Freebay TODO — Iterable Polish Backlog

> Living document. Check items off as they land. Add new items as they're discovered.
> Severity: `[CRIT]` = blocking, `[HIGH]` = important, `[MED]` = nice to have, `[LOW]` = eventual.

---

## Backend

### KNOWN ISSUES:
 
- [ ] - [Nest] 22100  - 10/07/2026, 21:28:31   ERROR [AllExceptionsFilter] [UNHANDLED] PATCH /chat/conversations/1d260245-1896-4aa8-b99e-b9b5307f80e1/background - request entity too large
PayloadTooLargeError: request entity too large
    at readStream (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\raw-body\index.js:163:17)
    at getRawBody (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\raw-body\index.js:116:12)
    at read (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\body-parser\lib\read.js:113:3)
    at jsonParser (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\body-parser\lib\types\json.js:88:5)
    at Layer.handleRequest (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\router\lib\layer.js:152:17)
    at trimPrefix (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\router\index.js:342:13)
    at C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\router\index.js:297:9
    at processParams (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\router\index.js:582:12)
    at next (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\router\index.js:291:5)
    at internalNext (C:\Users\Qiyana\Documents\GitHub\ME\freebay\nest-backend\node_modules\helmet\index.cjs:531:6)
esse erro acaba estourando no frontend, quebrando o chat devemos apenas mostrar uma mensagem no alert snackbar utilizado como componente no app caso a imagem seja maior q o permitido.
além disso vamos começar a salvar as imagens em discos para facilitar a migracao para um s3 ou bucket aws.

### Backend Cleanup Phases 5–10 `[done — 2026-07-09]`
- [x] Phase 5: ProcessWebhookUseCase decomposition — repos injected instead of raw PrismaService
- [x] Phase 6: N+1 fix in CreatePixPaymentUseCase — single `findPaymentInfo` query
- [x] Phase 7: ~30 mutation usecases converted from `Either<AppError, { verb: boolean }>` to `Either<AppError, void>`
- [x] Phase 8: RegisterBankAccountUseCase stubbed with `NotImplementedError`
- [x] Phase 9: P2002 leak in withdraw.usecase.ts moved to `WalletRepository.findWithdrawalByIdempotencyKey`
- [x] Phase 10: Documentation updated (CLAUDE.md, IMPROVEDARCH.md, REVIEWEDARCHITECTURETODO.md)
- [ ] Create GitHub issue: "feat: implement real PagBank recipient registration in RegisterBankAccountUseCase"

### Missing specs `[HIGH]`
- [ ] Add controller specs (0 of 15 controllers have tests)
- [ ] Add usecase specs for: `cart`, `category`, `chat`, `favorites`, `reports`, `tasks`, `repositories`
- [ ] Add integration specs for key flows (auth, orders, payments, escrow)

### Docs
- [ ] Add `nest-backend/README.md` with setup, architecture, and dev workflow

---

## Frontend
## KNOWN ISSUES
### STATE
- [ ] comment count doesnt add up whenever we comment on a post.(inside the comment section flow, updates correctly after we go back to the explore page)

### OVERALL 

- [ ] check if we are excluding the tokens propelry after logout(hasseenonboarding and others..)
- [ ] why we dont have any utils C:\Users\Qiyana\Documents\GitHub\ME\freebay\frontend\lib\shared\utils . we need to ensure we are using utils throught the app to reduce code and help with generic stuff

### FEED
- [ ] feed scroll leaves a header black bar background that obfuscates the view whenever u scroll down. needs to be hidden when scrolled so the feed fits entire screen. 
- [ ] ao clicar no botão de wallet sou redirecionado mas o freebay que fica ativo na navbar(parece que ainda esta internamente na rota do freebay, ja que posso dar swipe e abrir o drawer) e só se conserta se eu pressionar o back button.
- [ ] ao clicar nas notificações nao consigo voltar com o gesto de swipe como em outras telas, tem a ver com o drawer ou é algo de não pushar a rota?
### CHAT
- [ ] investigate the cause of this: on chatW/ConnectivityManager.CallbackHandler(  357): callback not found for CALLBACK_AVAILABLE message
- [ ] "nenhuma conversa aqruivada" o texto não esta centralizado.
- [ ] Chat nao renderiza as conversas 
disponiveis na main page do chat. investigar o fluxo.
-[ ] ao personalizar e trocar a cor , o 'Check' Não é atualizado conforme eu seleciono a cor
### Perfil
- [ ] verificação do perfil show modal aparece por cima da navbar e ao abrir o teclado a tela sobe e depois volta ao normal(investigue, provavelmente é um bug com o scroll que fizemos no feed) botão de fechar está mt dificil de ver no dark mode
- [ ] não consigo clicar em algum post que o usuario criou(no perfil dele) para abrir a tela do post(a mesma usada no feed.)
- [ ] não consigo dar swipe para trocar as abas(swipe horizontal para trocar de paginas)
- [ ] AO dar follow e unfollow na mesma pessoa, não consigo seguir ela novamente, pois da o erro de already following(nao devia ser o caso) investigue. 
[Nest] 22100  - 10/07/2026, 21:41:57   DEBUG [HTTP] [AUTH_HEADER] [REDACTED]
[Nest] 22100  - 10/07/2026, 21:41:57   ERROR [HTTP] [ERROR] POST /users/a48388c5-a63e-4e1a-adf7-3d257f383868/follow - 30ms - Already following
[Nest] 22100  - 10/07/2026, 21:41:57    WARN [AllExceptionsFilter] [APP] POST /users/a48388c5-a63e-4e1a-adf7-3d257f383868/follow - BAD_REQUEST: Already following
-[ ] on click on following: I/flutter (21963): [PROFILE] getFollowers data: {success: true, data: {users: [{id: 41e139d0-ecb8-4cb4-a6f4-08e2bbff5c66, displayName: qqq, avatarUrl: null, isVerified: false, reputationScore: 0}], total: 1, limit: 20, offset: 0}}
Another exception was thrown: Trailing widget consumes the entire tile width (including ListTile.contentPadding).
Another exception was thrown: RenderBox was not laid out: _RenderListTile#99784 relayoutBoundary=up12 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: RenderBox was not laid out: RenderPadding#89684 relayoutBoundary=up11 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: RenderBox was not laid out: RenderPadding#30b2e relayoutBoundary=up10 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: RenderBox was not laid out: RenderSemanticsAnnotations#8f406 relayoutBoundary=up9 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: RenderBox was not laid out: RenderPointerListener#efb84 relayoutBoundary=up8 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: RenderBox was not laid out: RenderSemanticsAnnotations#bc78c relayoutBoundary=up7 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: RenderBox was not laid out: RenderMouseRegion#51425 relayoutBoundary=up6 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: RenderBox was not laid out: RenderSemanticsAnnotations#14385 relayoutBoundary=up5 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: RenderBox was not laid out: RenderRepaintBoundary#58dc3 relayoutBoundary=up4 NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE
Another exception was thrown: 'package:flutter/src/rendering/sliver_multi_box_adaptor.dart': Failed assertion: line 629 pos 12: 'child.hasSize': is not true.
Another exception was thrown: Null check operator used on a null value
Another exception was thrown: Null check operator used on a null value
Another exception was thrown: RenderBox was not laid out: RenderPadding#30b2e relayoutBoundary=up10 NEEDS-PAINT

### Explorar
- [ ] filtro precisa ser exibido de uma forma melhor atualmente ocupa muito espaço na tela, também deve recolher o header e bottom nav ao scrollar 
- [ ] input não tem nenhum texto "Buscar Produto" até eu selecionar o input
- [ ] ao abrir o teclado a tela meio que quebra e temos o Another exception was thrown: A RenderFlex overflowed by 52 pixels on the bottom. overflow, talvez seja pq nao usamos singlechild scrollview? 
- [ ] ao trocar para a pagina de procurar pessoas o texto de input não é atualizado para buscar pessoas. achho que essa busca deve ser simplifcada tambem, talvez colocar em um novo botao nav.



### Design-system violations `[MED]`
- [x] `core/router/app_router.dart` — page transitions already use 150ms `Curves.linear` (`_buildPageWithSlideTransition`); stale item, no longer an issue
- [ ] `social_post.dart` — price tag uses `primaryContainer` instead of `surface_container_highest`
- [ ] Audit all pages for hardcoded `Colors.white` / `Colors.black` instead of `context.isDark` / theme extension
- [ ] Audit all pages for `BorderRadius.circular()` > 0

### Docs
- [x] Replace stale `frontend/README.md` (stock Flutter boilerplate) with project-specific README

---

## Database (Prisma)

### Enum migrations `[HIGH]`
- [ ] `Withdrawal.status` — currently bare `String`; migrate to `WithdrawalStatus` enum
- [x] `DirectConversation.status` — already `ConversationStatus` enum in schema

### Missing indexes `[MED]`
- [x] `Report.reportedUserId` — already indexed
- [ ] `Report.reportedPostId` — missing index
- [ ] Audit all FK columns for missing indexes

### Resolved — onDelete constraints
All onDelete constraints verified present in schema:
- `Order → Product` — `onDelete: Restrict`
- `Dispute → Order` — `onDelete: Cascade`
- `Category` self-reference — `onDelete: SetNull`
- `Comment → User` — `onDelete: Cascade`
- `CommentLike → User` — `onDelete: Cascade`

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
- [x] Align `AGENTS.md` — moot: `AGENTS.md` was slimmed down to diagrams-only and no longer describes DTO validation at all; conventions now live solely in `CLAUDE.md` (already correct: class-validator, not Zod)

---

## Reviews with Photos + Product Quantity `[done — this session]`

> Implemented in parallel. Reviews refactored to Clean Architecture (api/ → usecases/ → domain/ → data/);
> product quantity with stock validation at checkout, soldCount tracking, and status transitions.

### Backend
- [x] `ReviewImage` model in Prisma schema + migration `20260625000001`
- [x] Products: `quantity Int @default(1)` + `soldCount Int @default(0)` in schema
- [x] Reviews refactored: `domain/repositories/review.repository.ts` (abstract), `data/repositories/review-database.repository.ts` (concrete), `api/` (Controller+Service+Module+DTo), `usecases/create-review/`, `get-user-reviews/`, `can-review-order/`
- [x] `POST /reviews/orders/:orderId/images` — multipart upload (memoryStorage, 5MB limit), returns `{ imageId, url }`
- [x] `CreateReviewUseCase` — transação Prisma atômica com `ReviewImage.create`
- [x] Stock no checkout: `CreateOrderUseCase`, `CancelOrderUseCase`, `charge.completed`/`charge.expired` webhooks, `checkout-cart` — validam `quantity - soldCount`, incrementam/decrementam `soldCount`, setam `SOLD` quando esgota
- [x] Todo backend compila com `tsc --noEmit` (erros só em módulos não modificados: reports, users, wallet)

### Frontend
- [x] `review_entity.dart` — campo `images: List<String>` com `@JsonKey(defaultValue: [])`
- [x] `review_service.dart` — `uploadReviewImage()` (compress + multipart) + `createReview()` com upload sequencial
- [x] `create_review_page.dart` — image picker (câmera/galeria), preview grid max 5, upload progressivo
- [x] `review_card.dart` — galeria horizontal com `FullScreenImageViewer` ao tocar
- [x] `product_entity.dart` — campos `quantity` e `soldCount`
- [x] `product_detail_page.dart` — indicador de estoque (verde/laranja/"Última unidade"/"Vendido"/"Esgotado"), seletor de quantidade no bottom sheet (multi-unit)

### Known tech debt
- [ ] Upload de imagens em data URI (não base64 inline no backend) — migrar para upload direto S3/R2 com presigned URLs
- [ ] Validar `flutter analyze` no frontend
- [ ] Testar fluxos E2E: criar review com fotos, comprar produto multi-unidade, cancelamento parcial, webhook de expiração

---

## Testing & CI

### Backend
- [ ] `[HIGH]` Expand specs for untested modules: cart, category, chat, favorites, reports, tasks, repositories
- [x] `[MED]` Pilot `effect`-based integration tests on Disputes module — **done**, via the Domain Modeling +
  TDD initiative on Disputes (see `nest-backend/src/modules/disputes/CONTEXT.md` and
  `nest-backend/CONTEXT.md`/ADR-0001). Shipped beyond the original Fase 0–5 breakdown below: an explicit
  `DisputeTransitionPolicy` domain model, a deduped `DisputeResolutionExecutionService` (eliminating the
  drift risk between `ResolveDisputeUseCase` and `DisputeCleanupTask`), and a new `WithdrawDisputeUseCase`
  making the previously-dead `CANCELLED` status reachable (ADR-0002). The original phase breakdown is kept
  below for history; all of Fase 0–4 landed, folded into the broader initiative rather than as standalone PRs.

  <details><summary>Original Fase 0–5 breakdown (historical)</summary>

  **Fase 0 — Setup (1 PR)**
  - [x] 0.1: Adicionar `effect` (latest stable) em `nest-backend/package.json` — `npm install effect`
  - [x] 0.2: Rodar `npx tsc --noEmit` — confirmar que `effect` não quebra a compilação existente
  - [x] 0.3: Rodar `npm test` — confirmar que specs existentes continuam passando
  - [x] 0.4: Rodar `npm run test:integration` — confirmar que setup de integração existente funciona (Postgres + truncate)
  - [x] 0.5: Criar `src/modules/disputes/effect-harness/tags.ts` — `Context.Tag<PrismaService>` e `Context.Tag<NotificationService>`
  - [x] 0.6: Criar `src/modules/disputes/effect-harness/live-prisma.layer.ts` — Layer que conecta `PrismaClient` real contra `.env.test` (reusar pool de `setup-integration.ts` ou instanciar igual)
  - [x] 0.7: Criar `src/modules/disputes/effect-harness/test-notifications.layer.ts` — Layer que grava chamadas num array em vez de mandar FCM
  - [x] 0.8: Criar `src/modules/disputes/effect-harness/index.ts` — barrel export

  **Fase 1 — OpenDispute + TestClock (TDD)**
  - [x] 1.1–1.5: 47h59m/48h01m boundary tests, `now?: Date` injectable parameter on `open-dispute.usecase.ts`, `TestClock` demo
  - [x] 1.6: Seed helper extracted (`userFactory`/`productFactory`/`orderFactory`)

  **Fase 2 — Double-resolve guard (TDD + bugfix)**
  - [x] 2.1–2.4: guard added — routed through `DisputeTransitionPolicy.canResolve` (covers `RESOLVED` *and*
    `CANCELLED`, not just the originally-proposed `RESOLVED` check)
  - [x] 2.5: full suite green

  **Fase 3 — Auto-expiry cron (TDD)**
  - [x] 3.1–3.4: done — and the wallet-mutation logic the cron uses is now shared with `ResolveDisputeUseCase`
    via `DisputeResolutionExecutionService`, not a separate inline copy

  **Fase 4 — SubmitEvidence status transitions (TDD)**
  - [x] 4.1–4.6: done — same `DisputeTransitionPolicy` guard pattern as Fase 2

  **Fase 5 — Limpeza e verificação final**
  - [x] 5.1–5.5: see Verification section of the Disputes domain-modeling plan

  </details>

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
