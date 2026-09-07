# FreeBay Production Release Program Handoff

Generated: 2026-09-05

> **SUPERSEDED — last revised 2026-09-06.** The Q1–Q21 interview is finished. The canonical
> decision record and phase plan live at
> `~/.claude/plans/claude-resume-5808f309-5fa3-465d-a647-cb-smooth-hartmanis.md`.
> Device-testing guide: `docs/DEVICE_TESTING.md`. Do **not** resume the interview at Q9.
> Sections below are kept only for the verbatim user prompts and original evidence pointers —
> several of their risk/recon claims were refuted by audit. See "Revisions" immediately below.

## Revisions

### 2026-09-06 — scope change and eight new findings

**Scope reversal:** Stripe **Connect Express is no longer deferred** (user decision). Epic #1's
"Explicit exclusions" section still lists it as out of scope and is now stale on that point.
DM E2EE and shipping remain deferred. Platform account country locked to **Brazil**; app identity
unified on **`com.freebay.app`**.

Connect uses **separate charges and transfers** — the only pattern compatible with a multi-seller
cart plus delivery-gated release. Consequence: `application_fee_amount` must never be set; the
platform fee stays transfer math (`amount − sellerAmount`). Accounts are created through the
**Accounts v2 API** with the `recipient` configuration (`dashboard: express`,
`fees_collector/losses_collector: application`).

**Findings this session (all verified in code, none previously recorded):**

| # | Finding | Status |
|---|---|---|
| F1 | `POST /wallet/withdraw` debited the balance, wrote a `PENDING` row nothing ever processed, and discarded the PIX key. `register-bank-account` was a hard 501 for **PagBank**, the pre-Stripe provider. | Rail removed end to end; replaced by Connect payouts + Express dashboard link. |
| F2 | Sold inventory was consumed twice — order creation reserved `quantity`, then the payment webhook consumed `1` more. Expiry/cancel restored only `1`, permanently losing stock. | Fixed: sale is now a status confirmation only; restores use `order.quantity`. |
| F3 | `escrow-release.task.spec.ts` passed green while the code under test threw `TypeError: tx.order.updateMany is not a function`. The single test guarding auto-release asserted nothing about the release. | Fake spec deleted; replaced by a real-DB integration spec. |
| F4 | `updateInventoryOnSale` / `restoreInventoryOnExpiry` / `cancelOrder` were read-then-write with no lock under READ COMMITTED. | Fixed: conditional `updateMany` with atomic `decrement`. |
| F5 | `ActivateEscrowUseCase` was registered and exported but injected nowhere — a second, divergent implementation of the webhook credit path. | Deleted, including the orphaned repository method. |
| F6 | Cart checkout creates one Stripe session per item and, on partial failure, rolls back only the failing item, leaving orphan orders and reserved stock. | **Open** — see the plan's phase E. |
| F7 | `charge.refunded` and `charge.dispute.*` were unhandled; a Stripe-side refund left the seller credited. | Refund handled with transfer reversal; dispute events logged. |
| F8 | Frontend called `GET /notifications/unread-count` (route did not exist) and `POST /notifications/:id/read` against a `PATCH` route — badge stuck at 0, mark-as-read never persisted. | Both fixed. |

**Corrections to this document's own recon:**

- The Firebase admin JSON is **not** a leak. It is gitignored and untracked; the commits that
  contain it (`2ce9ffa`, `dc85385`) are reachable only from `refs/stash`, not from `HEAD` or any
  branch, so pushing this branch cannot carry the blob. Residual action is local hygiene only
  (`git stash drop` + `git gc --prune`).
- Non-zero `borderRadius` does **not** exist in `frontend/lib/` — all 57 occurrences are
  `BorderRadius.zero`. Do not budget work for it.
- Unpaginated list endpoints number **21**, not 12. The two that will actually hurt are
  `GET /chat/conversations/:id` (entire message history per open) and `GET /wallet/transactions`.
- Guest browsing was never missing — `GuestGateView` and its call sites already existed and were
  unreachable because `_publicRoutes` excluded the shell tabs. Fixed as a routing change.

This is the continuation checkpoint for the repository-wide FreeBay production-readiness program. A fresh agent must read this entire file before asking another question, planning work, changing code, creating GitHub issues, or opening a pull request.

## Immediate continuation

1. Work from `C:\Users\Qiyana\Documents\GitHub\ME\freebay` on branch `feat/production-hardening`.
2. Read root `AGENTS.md`, then invoke every relevant skill listed in **Suggested skills** below. The existing skills and AGENTS.md contain stale claims, so verify them against code before relying on them.
3. Verify `git status --short --branch` and confirm checkpoint commit `269d5bafa689992a6b11c23f00992f5b636a19ed` is present. The tree was clean immediately before this handoff file was added.
4. Resume `/grill-with-docs` one question at a time at **Question 9**, shown below. Give a recommended answer for every question. Do not dump all remaining questions on the user.
5. Record each answer immediately in this file or its eventual canonical planning artifact. Update the task list after every material decision.
6. Finish the 15-20 question agreement before implementation. The newly added digital-goods scope may take the interview to 20 questions.
7. After agreement, create a GitHub epic/map and modular implementation issues with evidence, dependencies, acceptance criteria, and verification commands.
8. Execute through modular agents using explore -> plan -> advise -> execute -> test -> security review -> code review. Parallelize independent domains, but serialize shared schema/contracts and financial state changes.
9. Release only after all agreed functionality and quality gates pass. There is no fixed deadline and no permission to cut quality, tests, security, accessibility, observability, or requested scope.
10. At the end, push the branch and open a pull request to the existing `master` branch. Do not open the PR early.

## Original user prompt, verbatim

```text
Improve this codebase as a whole, it currently is buggy and a lot of stuff are not properly implemented or are partially mocked, aim for maximum re-usability using patternized tokens(design system guidelines), read AGENTS.md and improve it since it has not been updated in a while, keep general guidelines for working in Freebay, improve UI Frontend User experience on breadcrumbs, swipe on pages(also add global cupertino or something to simplify gesture as it is now ANDROID AND IOS Natively, improve Google Sign in, stripe implementation and payment flow, personal info about the user, customizability, websockets on chat , location sharing, image handling, image editing whitin the app, feed algorithm ) make the codebase perfomance and fell off the app feel premium like X and instagram tap , video editing like tiktok , a proper category filter that doesnt look ugly and hard to filter, better drawer and also most importantly, swipe beetween screens like drawer<home <-> explore <-> wallet <-> chat <->  profile, improve pagination an all aspects of the codebase as a whole, separate this into modular agents also /grill-with-docs with me until we get into agreement like 15-20 questions , define a todolist and track issues in github please.
```

## Subsequent user instructions, verbatim

```text
use your tool to ask me bro, also we must improve push notifications and how its handled in app, take in some deeplinks and also improve onboarding , add that to the list and A, no prototype we gotta do this as soon as possible our app is not even in production yet and it must be released soon. not some half baked shit
```

```text
A
```

```text
at the end we open Pr to Main
```

```text
a
```

```text
A
```

```text
wdym cut quality bro, no shortcuts will be taken here, we have all the time in the world to realase this but this doesnt mean u need to be lazy, WORK HARD!!!. A.
```

```text
A
```

```text
also support for digital stuff!! to buy! A
```

```text
we wont be able to finish this grilling session in time, please create a .md checkpoint with our intent, nothing left out so we can continue where we left next context , with my original prompt
```

```text
no no, inside the repo
```

## Non-negotiable intent

- Build a complete, production-ready FreeBay, not a prototype or visual mock.
- Work hard and comprehensively. Do not trade quality for calendar speed.
- "As soon as possible" means parallelize independent work and remove waste; it does not mean ship unfinished flows.
- Android and iOS are the production products. Web is support-only for verified links, password reset, payment return/fallback pages, and any policy-required external purchase flow.
- Replace mocks, placeholders, pass-through implementations, and partially wired features with real end-to-end behavior.
- Fix root causes and shared contracts rather than patching each caller independently.
- Maximize reuse through existing design-system tokens, components, contracts, and deep module seams. Do not add speculative abstraction or duplicate helpers.
- Preserve FreeBay's Digital Brutalist visual identity unless a later explicit decision changes it.
- Deliver premium interaction quality comparable in responsiveness and polish to X, Instagram, and TikTok without copying their branding.
- Include deliberate social gestures and feedback such as double-tap interactions, pressed states, haptics, optimistic feedback, and safe rollback rather than cosmetic animation alone.
- Include push notifications, deep links, onboarding, digital goods, Google Sign-In, Stripe/Connect, personal data/privacy, customization, WebSocket chat, location sharing, image handling/editing, video editing, feed ranking, categories, drawer/navigation, pagination, performance, testing, security, and release operations.
- Track the agreed program in GitHub issues.
- Open the final pull request to `master` only after implementation, verification, security audit, and review are complete.

## Confirmed decisions

### Decision 1: Program destination

Production-ready core first. There is no prototype phase. Financial safety, identity, chat, uploads, navigation, pagination, notifications, deep links, onboarding, and core UX become reliable before release polish is considered complete.

### Decision 2: Existing working tree

The large uncommitted `feat/production-hardening` tree was declared the intended baseline. It was preserved and checkpointed rather than discarded.

Checkpoint evidence:

- Commit: `269d5bafa689992a6b11c23f00992f5b636a19ed`
- Subject: `chore: checkpoint production hardening baseline`
- Scope: 188 files, 6,990 insertions, 3,016 deletions.
- Commit hooks completed Dart formatting and scoped ESLint successfully.
- No push was performed.
- A broad backend lint invocation also scans generated `dist` and reported thousands of generated-file findings; the scoped source lint used by the hook passed. Fix lint scope/configuration later rather than treating generated output as source.

### Decision 3: Final pull request target

The final pull request targets the existing default branch `master`. The user used "Main" to mean the primary branch; do not create or migrate to a new `main` branch.

### Decision 4: Launch surfaces

Android and iOS launch as production clients. Full Flutter Web parity is not required. Web supports verified link fallback, password reset, payment return/cancel/pending pages, and policy-required purchase entry points.

### Decision 5: Schedule and quality

There is no fixed release date. Release as soon as every production gate passes. No quality, test, security, accessibility, observability, or requested-feature cuts are authorized.

### Decision 6: Customer payment relationship

The buyer pays FreeBay. FreeBay is the customer-facing merchant for marketplace transactions, appears on receipts/statements where applicable, and owns payment support, refunds, and disputes.

### Decision 7: Seller fund release

Use delivery-gated payout. FreeBay holds funds before releasing seller transfers, releases after buyer confirmation or an agreed timeout, and freezes release during disputes. The likely Stripe Connect pattern is Accounts v2 plus separate charges and transfers. Do not call this legal "escrow" in product copy without legal approval.

### Decision 8: Multi-seller checkout

One cart may contain multiple sellers and the buyer pays once. Checkout creates seller/order groups with independently tracked fulfillment, disputes, refunds, and seller transfers. The current per-item Stripe Session loop is not acceptable.

### Added requirement awaiting classification

Digital goods must be purchasable. Their exact product classes, store-compliant payment rails, entitlement model, mixed-cart behavior, fulfillment, versions, refunds, and seller release rules remain unresolved. This is the next interview branch.

## Repository state

- Repository: `https://github.com/vsmarlon/freebay`
- Local path: `C:\Users\Qiyana\Documents\GitHub\ME\freebay`
- Branch: `feat/production-hardening`
- Baseline checkpoint: `269d5ba`
- Default/final PR base: `master`
- GitHub open issues at checkpoint time: none.
- No GitHub epic/issues have been created yet.
- No branch push or pull request has been performed.
- Before adding this file, `git status --short --branch` showed only `## feat/production-hardening`.
- This handoff file is intentionally inside the repository at the user's direction and is expected to be the only post-checkpoint working-tree addition.

## Mandatory architecture and process rules

- Read root `AGENTS.md` and the matching `.agents/skills/*/SKILL.md` before changing a domain.
- Backend remains NestJS vertical feature slices with class-validator DTOs, one use case per file, explicit `Either<AppError, T>`, abstract repository seams, Prisma repositories, strict payload typing, and colocated tests.
- Frontend remains Flutter feature slices with Riverpod, Dio, GoRouter, FreeBay `Either`, shared design-system components, and real widget/integration tests.
- Money remains integer cents everywhere.
- Every relation and high-volume query needs deliberate delete behavior and indexing.
- Payment, refund, payout, transfer, entitlement, and webhook changes require transactional and idempotency tests.
- Expected business failures use typed errors rather than raw unhandled exceptions.
- Digital Brutalist rules currently mean zero radius, no blurred shadows, tonal depth, restrained `#8A1083`, Space Grotesk/Inter, dark mode, and fast motion. Existing violations must be resolved through tokens/components rather than scattered restyling.
- Preserve user changes. Never reset, clean, discard, or overwrite concurrent work.
- Do not skip hooks, force-push, amend failed commits, or commit secrets.
- Use Context7/current official documentation for framework, SDK, Stripe, Firebase, Apple, Google, or package decisions.
- Use physical-device verification for production mobile flows. Remote/cloud devices require explicit user authorization before allocation.

## Reconnaissance completed

Eight read-only modular agents mapped the repository, frontend UX/navigation, identity/profile, payments, real-time/media, feed/pagination, push/deep links/onboarding, and digital goods. Two external researchers checked current Flutter/package guidance, Stripe/Connect guidance, Firebase/deep-link guidance, and Apple/Google digital-goods policies.

### Actual stack and project map

- Backend: NestJS modules under `nest-backend/src/modules`, Prisma/PostgreSQL, Redis, Jest, Stripe Node.
- Frontend: Flutter with Riverpod, Dio, GoRouter, Freezed/JSON generation, Firebase Messaging, local notifications, Socket.IO, image picker/image processing, cached images, camera, and a local design-system package.
- Navigation uses `StatefulShellRoute.indexedStack` with five branches: feed/home, explore, wallet, chat, profile.
- Backend integration tests exist but main CI currently does not run them.
- Root `make test-integration` currently means Flutter web integration, not backend integration.
- `scripts/test-e2e.sh` references stale paths/scripts and is not reliable.
- Root `AGENTS.md`, `CLAUDE.md`, and untracked/generated guidance had duplicated or stale architecture claims. AGENTS.md must become a concise router to current source-of-truth documents rather than another copied architecture cache.

### Highest-priority baseline risks

#### Payments, orders, wallet, and Connect

- No working Stripe Connect seller onboarding, connected-account model, capability lifecycle, transfer, payout, reversal, or Connect webhook flow exists.
- Current "escrow" is only an internal balance/status projection.
- Buyer-favorable dispute resolution credits an internal wallet but does not call Stripe refunds.
- Withdrawals deduct internal balance and remain pending; no payout processor exists, and bank-account registration is a stub.
- Cart checkout creates one order and one Stripe Checkout Session per item, can leave partial reservations, discards usable payment URLs on the client, and has no cart-level idempotency.
- Quantity reservation increments/decrements `soldCount` by one instead of the purchased quantity.
- Webhook processing does not fully validate provider object ID, amount, currency, account, and payment status against the local transaction.
- Redis webhook deduplication is check-then-set, non-atomic, non-durable, and expires too early.
- `checkout.session.async_payment_succeeded` and related asynchronous/failure/refund/dispute events are not handled.
- PaymentSheet success is presented as completed before server-side webhook confirmation.
- Seller release, scheduled release, and dispute arithmetic are duplicated and race-prone; concurrent execution can double-credit balances.
- Transaction history is reconstructed from orders instead of an auditable immutable money ledger.
- Stripe API version is not pinned, configuration has a placeholder fallback, and migration strategy is contradictory.

Primary evidence:

- `nest-backend/src/modules/payments/providers/stripe-provider.ts`
- `nest-backend/src/modules/payments/usecases/process-webhook.usecase.ts`
- `nest-backend/src/modules/cart/usecases/checkout-cart.usecase.ts`
- `nest-backend/src/modules/cart/data/repositories/cart-database.repository.ts`
- `nest-backend/src/modules/orders/data/repositories/order-database.repository.ts`
- `nest-backend/src/modules/tasks/escrow-release.task.ts`
- `nest-backend/src/modules/disputes/services/dispute-resolution-execution.service.ts`
- `nest-backend/src/modules/wallet/usecases/withdraw.usecase.ts`
- `nest-backend/src/modules/wallet/usecases/register-bank-account.usecase.ts`
- `frontend/lib/features/payments/presentation/widgets/payment_view.dart`
- `frontend/lib/features/cart/presentation/pages/cart_checkout_page.dart`

#### Digital goods

- No Product fulfillment type, digital asset, entitlement, license, secure download, asset version, moderation state, or digital refund/revocation model exists.
- Order and UI state assume physical shipping/delivery for every purchase.
- No shipping-address snapshot, tracking, carrier, or proper physical fulfillment model exists either.
- `/uploads` is publicly served; it cannot store paid digital assets.
- Current Product creation supports listing images only, not private paid files.
- A grouped payment aggregate is required for one buyer payment with multiple seller orders.
- Digital and physical lines need separate fulfillment and seller-release policies.
- Paid assets need ownership, content validation, malware scanning/quarantine, private object storage, entitlement checks, short-lived signed URLs, auditing, throttling, immutable purchased versions, and refund revocation.

Current Apple/Google policy research as of 2026-09-05:

- Digital files/content/features purchased or unlocked inside the mobile app generally require StoreKit on iOS and Google Play Billing on Android.
- A third-party C2C seller and FreeBay's merchant relationship do not create an exemption.
- Physical goods and qualifying real-time person-to-person services can use Stripe.
- Reader/consumption-only and regional external-purchase programs are conditional and require explicit policy/program compliance.
- Store transactions do not split through Stripe Connect; FreeBay needs verified store receipts/server notifications plus its own seller allocation ledger and payout process.
- Mixed physical/digital carts must split into policy-compliant payment flows.
- Do not introduce Firebase Dynamic Links. Use verified Android App Links and iOS Universal Links.

Primary evidence:

- `nest-backend/prisma/schema.prisma`
- `nest-backend/src/modules/products/dtos/product.dto.ts`
- `nest-backend/src/modules/products/products.controller.ts`
- `nest-backend/src/modules/orders/dtos/order.dto.ts`
- `nest-backend/src/modules/upload/upload.controller.ts`
- `nest-backend/src/app.module.ts`
- `frontend/lib/features/product/presentation/pages/create_product_page.dart`
- `frontend/lib/features/orders/presentation/widgets/order_actions.dart`

Policy sources already researched:

- `https://developer.apple.com/app-store/review/guidelines/`
- `https://developer.apple.com/support/storekit-external-entitlement/`
- `https://support.google.com/googleplay/android-developer/answer/9858738?hl=en`
- `https://support.google.com/googleplay/android-developer/answer/10281818?hl=en`
- `https://docs.stripe.com/connect/separate-charges-and-transfers`

#### Push notifications

- FCM token is fetched and cached locally but never registered with the backend.
- Token refresh has no registered backend callback.
- Logout does not unregister/deactivate the device token.
- A single `User.fcmToken` cannot support multiple devices reliably.
- Foreground display exists, but local notification tap routing has no consumer.
- `FirebaseMessaging.onMessageOpenedApp` is absent.
- `getInitialMessage()` exists but is never consumed.
- Background/terminated tap routing is therefore incomplete.
- Backend sends are best-effort; failures are swallowed with no retry, invalid-token cleanup, delivery state, queue, or alerting.
- Notification WebSocket gateway exists but `NotificationService` never publishes through it.
- Preferences are arbitrary JSON and are not enforced by producers.
- Unread count route is called by Flutter but missing in the backend.
- Notification pagination contract is mismatched.
- Payload types/casing/target IDs are inconsistent; FOLLOW, DISPUTE, PAYMENT, MENTION, and order events cannot all route correctly.
- Notification DTOs do not match the persisted model.
- A Firebase Admin service-account JSON is tracked at `nest-backend/freebaythebay-firebase-adminsdk-fbsvc-dca2b26598.json`. Treat it as potentially exposed: remove it from source control, rotate credentials, and use environment/secret management before release. Never copy its contents into plans/issues/logs.

Recommended contract direction:

- One versioned, typed notification payload with stable `eventId`, category, title/body, and exactly one allowlisted deep-link destination.
- Use the same semantic payload for persistence, FCM data, local notification taps, in-app socket events, badges, and analytics.
- Validate IDs and authorization server-side; notification payloads are never a security boundary.

Primary evidence:

- `frontend/lib/shared/services/notification_service.dart`
- `frontend/lib/features/notifications/data/repositories/notification_repository.dart`
- `frontend/lib/features/notifications/presentation/providers/notifications_provider.dart`
- `frontend/lib/features/notifications/presentation/pages/notifications_page.dart`
- `nest-backend/src/modules/notifications/notifications.controller.ts`
- `nest-backend/src/modules/notifications/services/notification.service.ts`
- `nest-backend/src/modules/notifications/fcm.service.ts`
- `nest-backend/src/modules/notifications/notifications.gateway.ts`

#### Deep links and onboarding

- Android/iOS register only an unverified `freebay://` custom scheme.
- No central typed deep-link parser, destination allowlist, pending-link persistence, cold-start/resume dispatch, or authenticated continuation exists.
- Auth redirects discard the originally requested destination.
- Password-reset link producers disagree; one omits the email required by the Flutter route.
- Use HTTPS Android App Links and iOS Universal Links with working web fallback. Keep custom scheme only as an explicitly supported fallback if needed.
- Router/auth/onboarding readiness must gate pending-intent replay exactly once.
- Splash and router both navigate, producing an onboarding/auth race.
- Onboarding persistence exists and has three slides, but controls/progress lack strong semantics, analytics is absent, and animation timing conflicts with current design rules.
- Notification permission should be requested at a contextual onboarding moment or settings, not blindly during splash.

Native release blockers:

- Android and iOS Firebase project identifiers differ.
- iOS Firebase plist uses `com.company.freebay`, while Xcode uses `com.freebay.freebay`.
- No complete iOS APNs capability/entitlement/background-mode setup was found.
- Production package IDs, Firebase project, Apple team/provisioning, App Links domain, and Universal Links domain require owner confirmation.

Primary evidence:

- `frontend/lib/core/router/app_router.dart`
- `frontend/lib/core/router/app_routes.dart`
- `frontend/lib/features/auth/presentation/pages/onboarding_page.dart`
- `frontend/lib/features/auth/presentation/pages/splash_page.dart`
- `frontend/android/app/src/main/AndroidManifest.xml`
- `frontend/android/app/google-services.json`
- `frontend/ios/Runner/Info.plist`
- `frontend/ios/Runner/GoogleService-Info.plist`
- `frontend/ios/Runner.xcodeproj/project.pbxproj`
- `nest-backend/src/modules/auth/services/resend.service.ts`
- `nest-backend/src/shared/infra/email/email.service.ts`

#### Authentication, Google Sign-In, profile, privacy, and customization

- Google Sign-In uses the current `google_sign_in` 7.x API shape, but initialization can race and web requires the provider-rendered button path.
- Android/iOS Google/Firebase configuration appears inconsistent.
- Backend links an existing account by matching Google email without requiring `email_verified` or authenticated confirmation.
- Google payload `sub` is not explicitly validated.
- Logout leaves the stored biometric credential usable.
- Biometric login is bearer-token based, not truly device-bound, and rotated biometric tokens are not persisted by the frontend.
- Guest UI remains but the backend guest use case/route is deleted in the checkpoint baseline.
- No complete account deletion, user data export, device/session list, or field-level profile privacy exists.
- Raw CPF is stored alongside a hash; public/private profile rules need explicit decisions.
- Blocking is enforced in some feed/chat/search paths but not consistently across profiles, user posts, products, and every discovery surface.
- Notification preferences exist as arbitrary JSON but have no complete UX or enforcement.
- Theme is local-only; cross-device preference synchronization is unresolved.

Primary evidence:

- `frontend/lib/features/auth/presentation/controllers/auth_controller.dart`
- `frontend/lib/features/auth/data/repositories/auth_repository.dart`
- `frontend/lib/shared/services/storage_service.dart`
- `frontend/lib/shared/services/http_client.dart`
- `nest-backend/src/modules/auth/usecases/google-auth.usecase.ts`
- `nest-backend/src/modules/auth/usecases/biometric-login.usecase.ts`
- `nest-backend/src/modules/users/mappers/user.mapper.ts`
- `nest-backend/src/modules/social/data/repositories/post-database.repository.ts`
- `nest-backend/prisma/schema.prisma`

#### Navigation, breadcrumbs, drawer, categories, and frontend UX

- Five independent persistent branches already exist through `StatefulShellRoute.indexedStack`.
- `AppShell` wraps the whole body in a velocity-based horizontal `GestureDetector` to switch branches. It conflicts with iOS edge-back, drawer edge drag, carousels, stories, media viewers, chat gestures, and horizontal filter rows.
- This is not an interactive native page swipe. Preserve route-native back behavior and decide top-level branch swipe semantics separately.
- Pushed pages use Cupertino-style route transitions, while shell branches use custom transitions with timing inconsistent with design tokens.
- Breadcrumb infrastructure and `PageHeader` support exist, but adoption/back policy is inconsistent.
- Drawer edge opening works only from Feed and competes with requested global branch swiping.
- Explore has overlapping `ExplorarPage` and `ProductListPage` implementations with shared/leaking filter state.
- Category hierarchy is flattened into a fixed-height nested chip scroller with weak parent/child selection visibility.
- Bottom navigation lacks complete semantics/selected-state accessibility.
- Several high-volume paths still use raw `Image.network` instead of bounded cached images.
- Existing design-system components themselves violate documented no-shadow/no-divider/150ms rules. Fix package primitives/tokens first, then remove app-local duplication.

Primary evidence:

- `frontend/lib/core/components/app_shell.dart`
- `frontend/lib/core/router/app_router.dart`
- `frontend/lib/core/router/route_helpers.dart`
- `frontend/lib/core/router/navigation_tracker.dart`
- `frontend/libs/freebay_design_system/lib/components/page_header.dart`
- `frontend/lib/features/social/presentation/widgets/feed_drawer.dart`
- `frontend/lib/features/product/presentation/pages/explorar_page.dart`
- `frontend/lib/features/product/presentation/pages/product_list_page.dart`
- `frontend/lib/features/product/presentation/widgets/category_filter_panel.dart`
- `frontend/libs/freebay_design_system/lib/components/app_button.dart`
- `frontend/libs/freebay_design_system/lib/components/brutalist_drawer.dart`

#### Chat, WebSockets, location, images, and video

- NestJS Socket.IO `/chat` and Flutter socket service exist with auth, rooms, messages, typing, presence, deletion, and reactions.
- The conversation page sends normal/rich messages over HTTP, while socket send/outbox code is separate and largely unused.
- Optimistic reconciliation matches content/sender rather than a client message ID, allowing duplicates and collisions.
- Offline queue is memory-only, loses rich metadata, and clears before acknowledgement.
- No durable acknowledgement, retry, event sequence, idempotency key, deterministic ordering, resync, or multi-instance Redis adapter exists.
- Typing events do not revalidate room access; presence is process-local and assumes one socket per user.
- Token refresh does not refresh socket authentication.
- Read/delivery receipt paths are incomplete, and Flutter calls a read endpoint missing from the backend controller.
- Chat attachments accept client-controlled URLs. Uploads are publicly served and MIME checks trust reported metadata.
- View-once cannot be private while the underlying URL remains public.
- Exact location is persisted indefinitely without precision choice, expiry, revocation, deletion policy, or access audit.
- Image picking/compression/viewing exists. The current "edit" action only replaces/removes images; crop, rotate, adjustments, drawing, text, stickers, and non-destructive editing do not exist.
- Video MIME/schema support is partial, but there is no chat/feed player/editor/export/transcode/thumbnail/moderation pipeline.
- Full TikTok-like editing is a major native-media domain, not a button-sized task. It remains requested and must be deliberately scoped rather than silently deferred.

Primary evidence:

- `nest-backend/src/modules/chat/chat.gateway.ts`
- `nest-backend/src/modules/chat/chat.controller.ts`
- `nest-backend/src/modules/chat/services/chat-thread-access.service.ts`
- `nest-backend/src/modules/chat/data/repositories/conversation-database.repository.ts`
- `frontend/lib/shared/services/chat_socket_service.dart`
- `frontend/lib/features/chat/presentation/pages/chat_conversation_page.dart`
- `frontend/lib/features/chat/presentation/pages/location_picker_page.dart`
- `frontend/lib/features/chat/presentation/widgets/location_message_bubble.dart`
- `frontend/lib/core/components/image_picker_grid.dart`
- `frontend/lib/shared/services/image_upload_service.dart`
- `nest-backend/src/modules/upload/upload.controller.ts`

#### Feed, discovery, pagination, and performance

- Following feed uses chronological cursor pagination; explore ranks a fixed 300-candidate window in memory and then uses offset pagination.
- Mixing cursor and offset in one endpoint causes duplicates/skips as scores and new content change.
- Feed product posts likely omit expected product detail due to the selected Prisma include.
- No impression, dwell, hide/not-interested, product-open, or conversion event model exists, so a serious recommendation algorithm cannot be measured.
- Current explore score is naive recency plus aggregate engagement and follow boost.
- Product discovery has no GPS/radius model; User stores city/state only.
- Block/privacy filtering is inconsistent across social feed, products, profiles, search, and user posts.
- Comments fetch/build the full tree and only slice roots in memory; client "load more" repeats the same request.
- Notifications client sends offset that backend ignores.
- Orders, favorites, liked posts, stories, and my-products lists are unpaginated.
- Followers/following/blocked offset queries lack stable ordering.
- User posts merge posts/reposts in memory using an invalid shared cursor.
- Product cursor end detection should fetch `limit + 1`; load-more failures need inline retry without losing existing items.
- Prefer one cursor-first envelope with deterministic ordering, opaque cursor, `hasNextPage`, and append deduplication across list APIs. Reviews may retain totals if the UI genuinely displays them.
- Use a measured v1 ranking function based on available signals, deterministic tie-breaking, author diversity, freshness, and block/privacy filtering before adding ML.
- Add event measurement before claiming advanced personalization.

Primary evidence:

- `nest-backend/src/modules/social/data/repositories/post-database.repository.ts`
- `nest-backend/src/modules/social/types/social.types.ts`
- `frontend/lib/features/social/presentation/providers/feed_provider.dart`
- `frontend/lib/features/social/presentation/pages/feed_page.dart`
- `nest-backend/src/modules/products/data/repositories/product-database.repository.ts`
- `frontend/lib/features/product/presentation/controllers/product_controller.dart`
- `frontend/lib/core/components/infinite_scroll_listener.dart`
- `nest-backend/src/modules/social/data/repositories/comment-database.repository.ts`
- `nest-backend/src/modules/notifications/notifications.controller.ts`

## Current dependency/documentation findings

- Stripe Node is locked at `22.4.0`; Flutter Stripe is locked at `13.1.0`.
- `google_sign_in` is locked at `7.2.0`.
- `go_router` is locked at `15.1.3`.
- Riverpod is locked at `3.3.2`.
- Firebase Core is locked at `4.11.0`; Firebase Messaging at `16.4.1`; local notifications at `19.5.0`.
- Existing image packages already cover picking, resizing/encoding, caching, viewing, and camera capture. Do not add duplicate dependencies before testing those seams.
- No complete video editor/export engine is installed. FFmpegKit is retired; any replacement requires current native/platform research and deliberate licensing/build evaluation.
- Current Stripe guidance favors Accounts v2 dimensions, capability checks, webhooks as source of truth, dynamic payment methods, and separate charges/transfers for delayed seller release or multi-seller checkout.

## Proposed modular execution pipeline after agreement

This is a candidate sequencing map, not yet an approved implementation plan.

1. Release baseline and secrets
   - Remove/rotate tracked credentials, eliminate insecure production defaults, repair CI/test commands, establish clean release configuration and observability.
2. Shared contracts and data invariants
   - Typed pagination, notification/deep-link intents, payment aggregate/ledger, product fulfillment, attachment ownership, message idempotency, and design tokens.
3. Identity and boot
   - Google Sign-In, device-bound biometric/session lifecycle, personal data/privacy, account deletion/export, onboarding, app startup, deep links, and push token lifecycle.
4. Marketplace commerce
   - Physical fulfillment, multi-seller single-payment checkout, Stripe Connect seller onboarding, delivery-gated transfers, refunds/disputes/reversals, payouts, immutable ledger, inventory concurrency, and reconciliation.
5. Digital commerce
   - StoreKit/Play Billing or permitted alternative rails, receipt verification, entitlements, secure assets/downloads, seller allocation/payout, moderation, versions, refunds/revocation, and mixed-cart split.
6. Real-time communication and media
   - Durable socket contract, offline/resync/multi-device behavior, notification integration, private attachments, location privacy, image editor, video capture/playback/edit/export/transcode/moderation.
7. Premium navigation and discovery
   - Native back, conflict-free primary swipe/drawer behavior, breadcrumbs, design-system convergence, category UX, cursor migration, measured feed ranking, interactions, accessibility, and performance budgets.
8. Release proof
   - Backend unit/integration/concurrency tests, Flutter unit/widget/integration tests, Android/iOS physical-device matrix, Stripe/Firebase sandbox verification, security review, code review, profiling, store configuration, docs, issue closure, and final PR.

## GitHub tracking intent

No issues exist yet. After the interview reaches agreement:

- Create one canonical epic or Wayfinder map named around the FreeBay production release program.
- Create modular child issues only for sharp, agreed scopes. Do not create vague "improve everything" tickets.
- Use priority labels (`P0`, `P1`, `P2`), type labels (`bug`, `feature`, `security`, `test`, `documentation`, `architecture`), and area labels (`frontend`, `backend`, `database`, `payments`, `digital-goods`, `auth`, `chat`, `media`, `notifications`, `navigation`, `feed`, `release`).
- Every implementation issue must contain current-code evidence, intended behavior, out-of-scope boundaries, dependencies, migration/rollback notes where relevant, and executable acceptance checks.
- Use native GitHub dependencies/child relationships where available and refer to issues by linked title, not bare number.
- Financial/security blockers precede polish issues, but every explicitly agreed feature remains on the program map.
- Do not open the final PR until all release-scoped issues are implemented or consciously moved out of the release through a new explicit user decision.

## Interview status

The user requested approximately 15-20 questions and one question at a time. Eight questions are resolved. Digital goods added a major branch, so use up to 20 total rather than compressing unrelated decisions. If an answer exposes another hard-to-reverse choice, ask it rather than guessing, even if the count needs an explicit extension.

### Resolved questions 1-8

1. Destination: production-ready core first; no prototype.
2. Dirty baseline: preserve and checkpoint it.
3. Final PR: target `master`.
4. Launch surfaces: Android and iOS; support-only web.
5. Timing: no fixed deadline; release only at full quality.
6. Customer payment relationship: buyer pays FreeBay; FreeBay handles refunds/disputes.
7. Seller release: delivery-gated transfer with dispute freeze.
8. Cart: one buyer payment can include multiple sellers; seller orders release independently.

### Ask next: Question 9

Ask only this question, wait for the answer, and recommend option A based on the user's phrase "digital stuff to buy":

```text
Question 9 of up to 20 - What digital goods must FreeBay sell at launch?

Recommended: A

A. Downloadable/viewable files, media, templates, ebooks, software or license keys that buyers purchase and access through FreeBay. Native purchases will use StoreKit/Google Play Billing wherever store policy requires it, with verified server-side entitlements and seller payouts.
B. Only live one-to-one services or deliverables consumed outside the app, which can generally remain on Stripe.
C. Both A and B as distinct product types and payment/fulfillment flows.

A, B, or C?
```

### Remaining decision branches after Question 9

Ask one concrete decision at a time. Do not assume these suggested groupings are final if the answer creates a dependency.

10. Digital fulfillment: mixed physical/digital carts, access timing, versions, download/license limits, refunds after access, and seller release timing.
11. Seller onboarding: countries/entity types, Express seller dashboard versus full custom UI, capability readiness, and multi-device/account ownership.
12. Marketplace economics and risk: platform fee, Stripe/store fee allocation, negative balance liability, Radar/fraud policy, chargebacks, and reserves.
13. Identity access: guest mode fate, Google email linking confirmation, biometric device binding, session/device management, and web Google scope.
14. Personal data and customization: public/private fields, CPF handling, account deletion/export, username changes, blocking semantics, notification/theme preference sync.
15. Navigation contract: exact back behavior, branch history, swipe animation/physics, drawer edge precedence, nested horizontal gesture exclusions, breadcrumbs, and restoration.
16. Notifications/deep links/onboarding: production IDs/domain, Firebase project, multi-device tokens, permission timing, notification categories/privacy, verified links, reset-link destination, onboarding content and analytics.
17. Chat reliability: WebSocket versus HTTP send authority, acknowledgements/idempotency, offline persistence, read/delivery receipts, multi-device presence, reconnect/resync, and scale target.
18. Media and location: private attachment retention, exact versus approximate location, expiry/revocation, image-editor toolset, and moderation.
19. Video and feed/discovery: exact TikTok-like editor scope, server transcoding/CDN, feed goals/signals, analytics consent, category taxonomy, geographic search, ads/boosts, and pagination migration.
20. Release contract: performance budgets, accessibility level, supported OS versions/devices, observability/SLOs, test matrix, migration strategy, deployment environments, staged store rollout, and definition of done.

## Open high-impact owner facts

These are not permission to ask a batch. Resolve them through the one-at-a-time interview when their branch is reached:

- Canonical Android package ID.
- Canonical iOS bundle ID.
- Canonical Firebase project and whether current split projects are intentional.
- Production HTTPS domain for App Links, Universal Links, password reset, and payment returns.
- Apple Developer and Google Play account readiness.
- Stripe account country, platform legal entity/country, supported seller countries/entity types, and whether a Stripe representative has advised the integration.
- Platform fee and fee allocation.
- Seller dashboard/onboarding preference.
- Negative balance liability and reserve policy.
- Physical shipping scope and carrier/tracking expectations.
- Digital product classes and store-billing policy path.
- Digital entitlement, refund, moderation, and version policy.
- Whether one user may use multiple devices and receive pushes/chat simultaneously.
- Guest browsing requirement.
- Public/private profile fields and privacy/legal requirements.
- Exact location retention and sharing policy.
- Full video editor feature set and supported platforms.
- Feed product/social balance, ranking signals, analytics consent, and target metrics.
- Supported Android/iOS versions and physical test device matrix.

## Verification contract

Use the actual repository commands and fix stale documentation/scripts as part of the program.

Backend (`nest-backend`):

```bash
npm run tsc:check
npm run lint
npm test
npm run test:integration
npm run build
```

Frontend (`frontend`):

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Also require:

- Focused concurrency/idempotency tests for payments, ledger, inventory, refunds, transfers, payouts, entitlements, and duplicate webhooks.
- FCM foreground/background/terminated and tap-routing tests on physical Android and iOS.
- App Link/Universal Link cold-start, resume, unauthenticated continuation, malformed input, and web fallback tests.
- Google and biometric login/logout/account-switch tests.
- Socket reconnect/offline/duplicate/multi-device/read-delivery/security tests.
- Private-media authorization, MIME/content verification, signed URL, expiry, revocation, and orphan-cleanup tests.
- Digital store receipt/server-notification/refund/entitlement tests for every supported platform/payment rail.
- Navigation gesture conflict, restoration, native back, drawer, carousel/media, accessibility, and deep-link tests.
- Pagination duplicate/skip/end/retry/filter-reset tests for every migrated list.
- Frame profiling, image memory/cache checks, startup/network measurements, and explicit performance budgets.
- Security audit and correctness-focused diff review after each high-risk phase and before the final PR.
- Release builds and store configuration validation. iOS build/signing requires macOS/CI even though orchestration currently runs on Windows.

## Documentation intent

After decisions stabilize:

- Rewrite root `AGENTS.md` as concise, current, high-value guidance plus strong context pointers. Preserve general FreeBay rules but remove stale caches, duplication, nonexistent paths, and claims contradicted by code.
- Decide whether `CLAUDE.md` remains authoritative, becomes a pointer, or is reduced. Avoid maintaining duplicate architecture manuals.
- Keep Prisma schema as data-model source of truth and document only invariants/decisions the schema cannot explain.
- Add a root context map only if multiple bounded contexts genuinely need separate glossaries.
- Add ADRs only for hard-to-reverse, surprising tradeoffs: marketplace payment/ledger model, digital store payment rails, notification/deep-link contract, private media, and navigation gesture architecture are likely candidates after agreement.
- Never place secrets or personally identifiable information in docs or GitHub issues.

## Suggested skills

The next agent should invoke these when their branches activate:

- `grill-with-docs`
- `grilling`
- `domain-modeling`
- `wayfinder`
- `orchestrator`
- `writing-for-agents`
- `codebase-design`
- `freebay-system-design`
- `freebay-app-flows`
- `freebay-design-system`
- `freebay-flutter-feature`
- `freebay-backend-module`
- `freebay-data-model`
- `freebay-mobile-mcp`
- `stripe-best-practices`
- `connect-recommend`
- `connect-required-verification-information`
- `writing-great-tests`
- `diagnosing-bugs` when reproducing failures

## Current task list

Completed:

- Review FreeBay skills, root guidance, repository state, and GitHub context.
- Map frontend UX/design/navigation/media/feed gaps.
- Map backend/auth/payments/chat/location/pagination gaps.
- Map push notification/deep-link/onboarding gaps.
- Checkpoint the declared production-hardening baseline.
- Audit digital-goods code, security, fulfillment, and current mobile-store policy constraints.
- Create this continuation handoff.

Pending:

- Resume the interview at Question 9 and reach explicit agreement.
- Draft a file-specific phased plan and have an advisor stress-test it.
- Create the GitHub epic/map and modular issues.
- Update AGENTS.md and decision/context documentation.
- Implement every approved phase through modular agents.
- Add/run full unit, integration, concurrency, E2E, security, accessibility, and performance checks.
- Validate release-critical flows on physical Android and iOS.
- Perform final security and code review.
- Push `feat/production-hardening` and open the final PR to `master`.

## Completion criterion for the next session

The next session is complete only when it either:

- records the next user decision and updates this handoff/canonical decision artifact before continuing, or
- finishes the remaining interview, produces an advisor-approved implementation roadmap, and creates the agreed GitHub map/issues.

It must not silently start a broad rewrite before the agreement phase is complete.
