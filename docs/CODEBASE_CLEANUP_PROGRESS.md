# Codebase cleanup progress

## Scope and baseline

- Baseline: `HEAD 85c6135` (`feat/production-hardening`).
- Inherited WIP snapshot: `9677bb2386f569cb78ede928d52d276ee583b172`; preserved externally at `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-cleanup-85c6135-inherited.zip`.
- This document tracks the approved inherited WIP plus additional cleanup for duplication, performance, and clean architecture. No god modules or god functions.
- The real index/staging area is untouched. Coordinator owns the atomic commits; this file is the only file being changed in this pass.
- Inherited snapshot inventory: 332 paths — 178 modified, 135 added, 18 deleted, 1 renamed.
- `node scripts/ci-check.js` passed in the read-only plan. `safe*` and `TS any/as unknown as` scans found no matches; ordinary unsafe casts remain to be reviewed.
- Backend baseline: `npm run tsc:check` passed, `npm run lint` passed, and `npm test -- --runInBand` passed with 109 suites / 639 tests in 109s.
- Frontend baseline: `flutter analyze --no-pub --fatal-infos lib test libs/freebay_design_system/lib` failed on 5 `unnecessary_underscores` infos in the socket lifecycle test; `flutter test --no-pub` reached 202 passed / 1 failed because the view-once test expected `mensagem revelada`; format check found 534 files, 28 needing formatting.
- On 2026-09-24, the resumed repair pass completed the stale Flutter enum-model regeneration, enum-based test-double/assertion migration, lint/format cleanup, and Prisma-generated enum typing repairs. The scoped build-repair review passed; the broader cleanup review, integration tests, and device checks remain pending.

### Resumed repair pass — 2026-09-24

- Regenerated stale Flutter Freezed/JSON enum models and migrated enum-based test doubles/assertions in chat, orders, payments, follow-state, and story-response tests.
- Replaced invalid Prisma `Enum.Member` annotations with generated enum types in the chat DTO and mapper.
- The actual index/staging area remained untouched. No guard or credential changes were made after the integration prerequisite rejected the configured test user.
- Native `task` reviewer verdict: **APPROVE**, covering repair snapshots `c8b787f206c9f44459c0d8f1f3deac90347b0dca` → `0ff4b290598faefa44a35e000c6786b4c5f36d92`. The review found no actionable defects in enum wire compatibility, generated outputs, typed test doubles, or assertions.

## Execution order

| Commit scope | Owner | Boundary |
|---|---|---|
| C1 | FE data commerce | Cart, orders, payments, disputes, reviews data/domain/provider wiring. Additive HTTP adapters first. |
| C2 | FE presentation/shared | Presentation decomposition, shared types, design-system cleanup, regression tests. |
| B1 | BE chat/catalog/core | Chat, products, categories, social, stories; Prisma adapters and query decomposition. |
| B2 | BE finance | Cart, orders, payments, disputes, reviews, wallet; transaction-safe Prisma adapters. |
| B3 | BE users/auth/tooling | Users, auth, shared infrastructure, guards, tooling and gates. |
| D0 | Coordinator | Docs, workflow/design guidance, final root gates. |

Additive frontend HTTP and backend Prisma adapters land as separate commits before deletion. Delete legacy bases only after the last migrated caller is absent from the commit snapshot. Root bans and gates are last. Each commit is stack/module atomic and must carry its focused tests.

## Progress

| Work item | Result |
|---|---|
| Inherited snapshot preservation | planned; ZIP path recorded above |
| Inherited frontend changes | implemented-awaiting-final-verification; see C1/C2 manifest rows |
| Inherited backend changes | implemented-awaiting-final-verification; see B1/B2/B3 manifest rows |
| Duplication cleanup | active; forwarding services removed and contracts/adapters added; caller inventory still running |
| Performance cleanup | active; visible-tab request reduction covered by focused test; measure remaining changes |
| Clean-architecture cleanup | active; HTTP/Prisma seams and usecase/repository orchestration are being enforced |
| Finite states/modes | active; prefer enums; replace magic policy numbers with named constants |
| Legacy frontend base deletion | planned after final migrated caller |
| Legacy backend base deletion | planned after final migrated caller |
| Root bans and CI gates | planned last |

## Verification ledger

| Area | Workdir | Command | Result |
|---|---|---|---|
| Root architecture/gates | `.` | `node scripts/ci-check.js` | passed |
| Root tests | `.` | `npm run test:ci-scripts` | passed: 3 tests |
| Backend safety tests | `nest-backend` | `npm run test:safety` | passed: 5 tests |
| Backend typecheck | `nest-backend` | `node ./node_modules/typescript/bin/tsc --noEmit --incremental false --pretty false` | passed |
| Backend unit tests | `nest-backend` | `npm test -- --runInBand` | passed: 110 suites / 640 tests |
| Backend chat tests | `nest-backend` | `npx jest src/modules/chat --runInBand` | passed: 15 suites / 97 tests |
| Backend lint | `nest-backend` | `npm run lint` | passed |
| Backend build | `nest-backend` | `npm run build` | passed; entry artifact `nest-backend/dist/src/main.js` exists |
| Backend integration tests | `nest-backend` | `npm run test:integration -- --runInBand` | did not run: guarded sync failed with Prisma P1000 authentication rejected for the configured test user against local `freebay_test_db`; no guard/credential changes |
| Frontend code generation | `frontend` | `dart run build_runner build --delete-conflicting-outputs` | passed: 127 outputs; installed build_runner warned that the obsolete flag was ignored |
| Frontend analysis | `frontend` | `flutter analyze --no-pub --fatal-infos lib test libs/freebay_design_system/lib` | passed: no issues |
| Frontend tests | `frontend` | `flutter test --no-pub --coverage` | passed: 214 tests; focused repair tests: 19 passed |
| Frontend formatting | `.` | `dart format --output=none --set-exit-if-changed frontend/lib frontend/test frontend/libs/freebay_design_system/lib` | passed: 543 files / 0 changed |
| Frontend debug build | `frontend` | `flutter build apk --debug --no-pub` | passed; `frontend/build/app/outputs/flutter-apk/app-debug.apk` exists; Kotlin plugin compatibility warning was nonblocking |
| Database/schema | `nest-backend` | `npm run prisma:generate` / `npm run db:sync` | pending; run only for applicable schema work |
| Device smoke | `frontend` | approved device flow and evidence checklist | not run; no device result claimed |
| Build-repair review | `.` | native `task` reviewer, repair snapshots above | APPROVE; integration remains environment-blocked |
| Broader cleanup review | `.` | inherited cleanup review | pending |

## Implemented batches awaiting final verification

- **FE commerce adapters:** five forwarding services were removed in favor of domain contracts plus HTTP repositories. Review-image sequencing is preserved. Focused 13 tests pass; `sales_list_provider_test` still needs import migration.
- **FE chat/social/socket:** Either pattern matching and truth-table handling, archived-state aliasing, social JSON narrowing, and `AppRoutes` use are in place. The socket test's 5 analyzer infos were fixed. Focused chat tests (22), view-once tests (3), and chat-state tests (5) passed in overlapping runs; counts are not additive. The view-once assertion was corrected after inspecting reveal behavior.
- **FE UI/orders:** integer-cent parser and create/edit field reuse are in place. The lazy visible-tab request test proves 2 requests became 1 initial request. Ten focused tests plus one dialog test pass.
- **BE repositories/events:** typed payload assertions were removed from chat, products, admin, social, orders, payments, and cart/wallet paths. Webhook handling now uses exact discriminated events with narrowed errors. Finance: 7 suites / 71 tests and another 3 suites / 25 tests passed. Core: 42 suites / 164 tests passed; 4 users suites were transiently blocked by concurrent edits, with final typecheck subsequently green across finance/users.
- **BE users/auth/tooling:** social controller Prisma orchestration moved into usecase/repository seams. Seven suites / 56 tests pass. The ESLint `any` test exemption and nested-unknown restriction were removed. Raw-route-props gate tests: 3 passed.
- These batches are **not complete** until the final review, integration, device checks, and remaining inherited work pass. No actual net deletion is reported until all new files are accounted for.

## Active cleanup inventory

Inventory is running for remaining duplication, performance hot spots, ordinary unsafe casts, and finite states/modes. Prefer enums for finite states/modes and named constants for magic policy numbers. Do not introduce god modules/functions; preserve one atomic commit per stack/module and keep tests with the owning change.

## Inherited per-file manifest

Status is intentionally `planned` for every inherited path until its owning atomic commit is verified. The scope code is the target commit, not a claim that the current file already conforms.

| Path | Stack/module owner / target commit scope | Status |
|---|---|---|
| `.agents/skills/freebay-backend-module/SKILL.md` | D0 — docs/design guidance | planned |
| `.agents/skills/freebay-flutter-feature/SKILL.md` | D0 — docs/design guidance | planned |
| `.claude/skills/freebay-backend-module/SKILL.md` | D0 — docs/design guidance | planned |
| `.claude/skills/freebay-flutter-feature/SKILL.md` | D0 — docs/design guidance | planned |
| `.github/workflows/ci.yml` | B3 — users/auth/tooling and final gates | planned |
| `.github/workflows/flutter.yml` | B3 — users/auth/tooling and final gates | planned |
| `.husky/pre-commit` | B3 — users/auth/tooling and final gates | planned |
| `AGENTS.md` | D0 — docs/design guidance | planned |
| `CLAUDE.md` | D0 — docs/design guidance | planned |
| `Makefile` | B3 — users/auth/tooling and final gates | planned |
| `README.md` | D0 — docs/design guidance | planned |
| `docs/adr/0001-generic-user-facing-errors.md` | D0 — docs/design guidance | planned |
| `frontend/DESIGN.md` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_card.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_card_image.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_dialog.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_dialog/app_dialog_actions.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_dialog/app_dialog_body.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_dialog/app_dialog_header.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_shell.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_video_viewer.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_video_viewer/video_source_resolver.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/app_video_viewer/video_viewer_controls.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/brutalist_safe_link_dialog.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/full_screen_image_viewer.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/safe_link_destination.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/social_post.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/social_post/post_action_chrome.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/social_post/post_content.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/social_post/post_header.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/social_post/post_labels.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/components/social_post/post_media.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/freebay.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/router/routes/chat_routes.dart` | C2 — presentation/shared | planned |
| `frontend/lib/core/ui.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/data/repositories/auth_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/controllers/auth_controller.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/controllers/auth_dependencies.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/controllers/auth_google_authentication.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/controllers/auth_session_lifecycle.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/pages/complete_profile_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/pages/login_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/pages/register_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/pages/splash_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/pages/splash_widgets.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/widgets/auth_header.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/widgets/enable_biometry_sheet.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/auth/presentation/widgets/google_auth_button.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/cart/data/services/cart_service.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/chat/data/repositories/chat_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/archived_chats_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/chat_conversation_actions.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/chat_conversation_lifecycle.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/chat_conversation_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/chat_conversation_selection.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/chat_list_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/chat_list_states.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/conversation_details_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/image_editor_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/pages/new_chat_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/providers/chat_provider.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/providers/conversation_messages_provider.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/chat_attachment_flow.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/chat_conversation_body.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/chat_conversation_composer.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/chat_conversation_header.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/chat_list_loading_tile.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/chat_list_tile.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/chat_media_composer.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/chat_theme_picker.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/conversation_details/conversation_details_sections.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/draw_palette.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/image_editor_models.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/image_editor_paint.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/image_editor_toolbar.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/image_editor_views.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/image_message_bubble.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/message_bubble.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/message_bubble/expandable_text_message.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/message_bubble/read_status_icon.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/new_chat/new_chat_product_composer.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/new_chat/new_chat_user_results.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/chat/presentation/widgets/new_chat/new_chat_user_tile.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/dispute/data/services/dispute_service.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/favorites/data/services/favorites_service.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/notifications/data/repositories/notification_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/onboarding/presentation/pages/onboarding_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/onboarding/presentation/pages/onboarding_slides.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/orders/data/services/order_service.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/orders/presentation/pages/order_detail_page.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/orders/presentation/pages/orders_page.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/orders/presentation/pages/orders_tab.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/orders/presentation/widgets/order_card.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/orders/presentation/widgets/sales_status_filters.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/payments/data/services/payment_service.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/product/data/repositories/category_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/product/data/repositories/product_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/product/presentation/pages/create_product_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/product/presentation/pages/edit_product_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/product/presentation/pages/product_detail_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/product/presentation/widgets/escrow_trust_banner.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/product/presentation/widgets/product_form_fields.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/data/repositories/profile_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/data/services/block_service.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/data/services/follow_service.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/providers/follow_status_provider.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/biometry_setting_tile.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/profile_avatar.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/profile_banner.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/profile_header.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/profile_help_sheet.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/profile_identity.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/profile_media_actions.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/profile_settings_sheet.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/profile/presentation/widgets/profile_stats.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/reviews/data/services/review_service.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/reviews/presentation/widgets/review_card.dart` | C1 — commerce data/domain wiring | planned |
| `frontend/lib/features/social/data/repositories/social_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/data/repositories/social_repository_parts/social_repository_discovery.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/data/repositories/social_repository_parts/social_repository_feed.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/data/repositories/social_repository_parts/social_repository_saves.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/data/repositories/social_repository_parts/social_repository_stories.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/domain/usecases/get_post_details_usecase.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/controllers/story_submission_coordinator.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/pages/comment_bottom_sheet.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/pages/create_post_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/pages/create_story_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/pages/feed_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/pages/post_details_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/pages/story_viewer_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/providers/post_details_provider.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/feed_drawer.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/feed_drawer_footer.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/feed_drawer_sections.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/feed_header.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/feed_intro_sections.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/feed_post_list.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/post_details_comment_tree.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/post_details_post_section.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/post_details_skeleton.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/story_capture_view.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/story_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/social/presentation/widgets/story_preview_view.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/wallet/data/repositories/wallet_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/wallet/presentation/pages/wallet_page.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/wallet/presentation/widgets/wallet_balance.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/wallet/presentation/widgets/wallet_content.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/wallet/presentation/widgets/wallet_error_states.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/wallet/presentation/widgets/wallet_history.dart` | C2 — presentation/shared | planned |
| `frontend/lib/features/wallet/presentation/widgets/wallet_payout_section.dart` | C2 — presentation/shared | planned |
| `frontend/lib/shared/http/request_either.dart` | C2 — presentation/shared | planned |
| `frontend/lib/shared/repositories/base_http_repository.dart` | C2 — presentation/shared | planned |
| `frontend/lib/shared/services/chat_socket_service.dart` | C2 — presentation/shared | planned |
| `frontend/lib/shared/services/http_client.dart` | C2 — presentation/shared | planned |
| `frontend/lib/shared/services/storage_service.dart` | C2 — presentation/shared | planned |
| `frontend/lib/shared/utils/date_utils.dart` | C2 — presentation/shared | planned |
| `frontend/libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart` | C2 — presentation/shared | planned |
| `frontend/libs/freebay_design_system/lib/components/brutalist_drawer.dart` | C2 — presentation/shared | planned |
| `frontend/libs/freebay_design_system/lib/components/shimmer_skeleton.dart` | C2 — presentation/shared | planned |
| `frontend/libs/freebay_design_system/lib/freebay_design_system.dart` | C2 — presentation/shared | planned |
| `frontend/libs/freebay_design_system/pubspec.lock` | C2 — presentation/shared | planned |
| `frontend/libs/freebay_design_system/pubspec.yaml` | C2 — presentation/shared | planned |
| `frontend/pubspec.lock` | C2 — presentation/shared | planned |
| `frontend/pubspec.yaml` | C2 — presentation/shared | planned |
| `frontend/test/core/components/app_shell_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/core/router/app_router_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/auth/biometry_owner_wiring_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/auth/google_auth_usecase_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/chat/chat_list_state_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/chat/message_bubble_view_once_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/chat/new_chat_page_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/chat/repro_conversation_open_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/onboarding/welcome_setup_page_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/profile/follow_state_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/profile/saved_posts_page_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/social/post_details_comments_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/features/wallet/wallet_controller_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/refactor_regressions/auth_session_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/refactor_regressions/chat_refresh_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/refactor_regressions/conversation_reload_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/refactor_regressions/product_form_fields_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/refactor_regressions/social_response_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/shared/http/request_either_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/shared/services/chat_socket_service_lifecycle_test.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/support/auth_test_doubles.dart` | C2 — presentation/shared tests | planned |
| `frontend/test/support/test_users.dart` | C2 — presentation/shared tests | planned |
| `nest-backend/.husky/pre-commit` | B3 — users/auth/tooling and final gates | planned |
| `nest-backend/package-lock.json` | B3 — users/auth/tooling and final gates | planned |
| `nest-backend/package.json` | B3 — users/auth/tooling and final gates | planned |
| `nest-backend/src/app.module.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/admin/data/repositories/moderation-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/auth-web-session.controller.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/auth.controller.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/auth.controller.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/auth.module.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/auth.service.enrollment.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/auth.service.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/auth.service.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/data/repositories/password-recovery-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/data/repositories/user-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/guards/jwt.strategy.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/guards/web-origin.guard.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/auth-usecases.module.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/biometric-login.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/biometric-login.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/consume-magic-link.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/consume-magic-link.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/enroll-biometric.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/enroll-biometric.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/forgot-password.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/forgot-password.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/google-auth.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/google-auth.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/login.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/login.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/logout-session.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/refresh-mobile-session.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/refresh-mobile-session.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/register.usecase.integration-spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/register.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/register.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/usecases/request-magic-link.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/auth/usecases/revoke-biometric.usecase.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/utils/session-policy.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/auth/utils/web-session-cookies.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/bug-reports/data/repositories/bug-report-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/cart/data/repositories/cart-database.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/cart/usecases/checkout-cart.usecase.ts` | B2 — finance | planned |
| `nest-backend/src/modules/cart/usecases/checkout-cart/checkout-cart-compensation.ts` | B2 — finance | planned |
| `nest-backend/src/modules/cart/usecases/checkout-cart/checkout-cart-payment.ts` | B2 — finance | planned |
| `nest-backend/src/modules/cart/usecases/checkout-cart/checkout-cart-planner.ts` | B2 — finance | planned |
| `nest-backend/src/modules/cart/usecases/checkout-cart/checkout-cart-reservation.ts` | B2 — finance | planned |
| `nest-backend/src/modules/cart/usecases/checkout-cart/checkout-cart.types.ts` | B2 — finance | planned |
| `nest-backend/src/modules/category/data/repositories/category-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/chat.controller.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/chat/chat.controller.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/chat.gateway.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/data/repositories/conversation-database.repository.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/chat/data/repositories/conversation-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/data/repositories/conversation-preference-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/data/repositories/conversation/lookups.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/data/repositories/conversation/messages.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/data/repositories/conversation/reactions-media.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/dtos/chat.dto.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/dtos/conversation-response.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/data/repositories/conversation/payloads.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/usecases/get-conversations.usecase.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/chat/usecases/get-messages.usecase.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/chat/usecases/get-starred-messages.usecase.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/chat/usecases/get-unified-conversations.usecase.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/chat/usecases/location-message-metadata.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/usecases/send-message.usecase.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/chat/usecases/send-message.usecase.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/chat/usecases/test-fixtures.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/disputes/data/repositories/dispute-database.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/favorites/data/repositories/favorite-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/notifications/data/repositories/notification-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/orders/data/repositories/order-database.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/orders/data/repositories/order-mutation.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/orders/data/repositories/order-read.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/orders/data/repositories/order-reservation.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/orders/orders.controller.spec.ts` | B2 — finance tests | planned |
| `nest-backend/src/modules/orders/orders.controller.ts` | B2 — finance | planned |
| `nest-backend/src/modules/orders/usecases/get-order.usecase.spec.ts` | B2 — finance tests | planned |
| `nest-backend/src/modules/orders/usecases/get-order.usecase.ts` | B2 — finance | planned |
| `nest-backend/src/modules/orders/usecases/list-sales-orders.usecase.spec.ts` | B2 — finance tests | planned |
| `nest-backend/src/modules/orders/usecases/list-sales-orders.usecase.ts` | B2 — finance | planned |
| `nest-backend/src/modules/orders/usecases/order-usecases.module.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/data/repositories/connect-account-database.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/data/repositories/payment-group-database.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/data/repositories/transaction-database.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/data/repositories/transaction-guarded-claims.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/data/repositories/transaction-reconciliation.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/data/repositories/transaction-repository-di.spec.ts` | B2 — finance tests | planned |
| `nest-backend/src/modules/payments/data/repositories/transaction-upsert.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/payments.controller.spec.ts` | B2 — finance tests | planned |
| `nest-backend/src/modules/payments/providers/stripe-connect-client.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/providers/stripe-provider.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/providers/stripe-webhook-verifier.ts` | B2 — finance | planned |
| `nest-backend/src/modules/payments/usecases/process-refund.usecase.spec.ts` | B2 — finance tests | planned |
| `nest-backend/src/modules/payments/usecases/process-webhook.usecase.spec.ts` | B2 — finance tests | planned |
| `nest-backend/src/modules/products/data/repositories/category-traversal.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/products/data/repositories/product-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/reports/data/repositories/report-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/reviews/data/repositories/review-database.repository.ts` | B2 — finance | planned |
| `nest-backend/src/modules/social/data/repositories/comment-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/data/repositories/feed-affinity.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/social/data/repositories/like-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/data/repositories/post-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/data/repositories/post-query-helpers.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/data/repositories/saved-post-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/data/repositories/share-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/social-read.controller.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/social.controller.ts` → `nest-backend/src/modules/social/social-write.controller.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/social.module.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/social/usecases/social-test-fixtures.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/social/usecases/social.usecase.spec.ts` | B1 — chat/catalog/core tests | planned |
| `nest-backend/src/modules/stories/data/repositories/story-database.repository.ts` | B1 — chat/catalog/core | planned |
| `nest-backend/src/modules/users/data/repositories/account-lifecycle-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/data/repositories/account-lifecycle-repository-di.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/users/data/repositories/block-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/data/repositories/follow-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/data/repositories/phone-verification-database.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/data/repositories/user-data-export.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/dtos/user-response.class.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/usecases/user-test-fixtures.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/users/usecases/user.usecase.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/users/users-account.controller.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/users-controllers.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/modules/users/users-discovery.controller.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/users-social.controller.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/users.controller.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/users/users.module.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/modules/wallet/data/repositories/wallet-database.repository.ts` | B2 — finance | planned |
| `nest-backend/src/shared/core/either.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/decorators/endpoints.decorator.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/decorators/index.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/decorators/strict-origin.decorator.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/guards/origin.guard.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/infra/email/email.service.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/infra/prisma/base-prisma.repository.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/infra/prisma/repository-response.spec.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/src/shared/infra/prisma/repository-response.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/shared.module.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/src/shared/utils/file.utils.ts` | B3 — users/auth/tooling | planned |
| `nest-backend/test/factories/order.factory.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/test/factories/product.factory.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/test/factories/user.factory.ts` | B3 — users/auth/tooling tests | planned |
| `nest-backend/test/utils/test-helpers.ts` | B3 — users/auth/tooling tests | planned |
| `package.json` | B3 — users/auth/tooling and final gates | planned |
| `scripts/ci-check.js` | B3 — users/auth/tooling and final gates | planned |
| `scripts/ci-check.test.js` | B3 — users/auth/tooling tests | planned |

## Current tracking file

| Path | Stack/module owner / target commit scope | Status |
|---|---|---|
| `docs/CODEBASE_CLEANUP_PROGRESS.md` | D0 — coordinator-owned cleanup ledger | in progress |

## Current delta manifest

These paths are present in the current working-tree diff/status but were not in the inherited 332-path snapshot. They are listed once here; each remains `implemented-awaiting-final-verification`, not complete.

| Path | Stack/module owner / target commit scope | Status |
|---|---|---|
| `frontend/lib/core/utils/currency_utils.dart` | C2 — shared type/format cleanup | implemented-awaiting-final-verification |
| `frontend/lib/features/cart/data/repositories/cart_repository.dart` | C1 — commerce HTTP repository | implemented-awaiting-final-verification |
| `frontend/lib/features/cart/domain/repositories/cart_repository.dart` | C1 — commerce domain contract | implemented-awaiting-final-verification |
| `frontend/lib/features/cart/presentation/providers/cart_provider.dart` | C1 — commerce provider wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/dispute/data/repositories/dispute_repository.dart` | C1 — commerce HTTP repository | implemented-awaiting-final-verification |
| `frontend/lib/features/dispute/domain/repositories/dispute_repository.dart` | C1 — commerce domain contract | implemented-awaiting-final-verification |
| `frontend/lib/features/dispute/presentation/providers/dispute_providers.dart` | C1 — commerce provider wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/orders/data/repositories/order_repository.dart` | C1 — commerce HTTP repository | implemented-awaiting-final-verification |
| `frontend/lib/features/orders/domain/repositories/order_repository.dart` | C1 — commerce domain contract | implemented-awaiting-final-verification |
| `frontend/lib/features/orders/domain/usecases/can_review_order_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/orders/domain/usecases/cancel_order_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/orders/domain/usecases/get_my_purchases_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/orders/domain/usecases/get_my_sales_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/orders/presentation/providers/order_providers.dart` | C1 — commerce provider wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/payments/data/repositories/payment_repository.dart` | C1 — commerce HTTP repository | implemented-awaiting-final-verification |
| `frontend/lib/features/payments/domain/repositories/payment_repository.dart` | C1 — commerce domain contract | implemented-awaiting-final-verification |
| `frontend/lib/features/payments/domain/usecases/create_payment_intent_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/payments/domain/usecases/create_payment_session_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/payments/presentation/providers/payment_providers.dart` | C1 — commerce provider wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/reviews/data/repositories/review_repository.dart` | C1 — commerce HTTP repository | implemented-awaiting-final-verification |
| `frontend/lib/features/reviews/domain/repositories/review_repository.dart` | C1 — commerce domain contract | implemented-awaiting-final-verification |
| `frontend/lib/features/reviews/domain/usecases/can_review_order_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/reviews/domain/usecases/create_review_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/reviews/domain/usecases/get_user_reviews_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/reviews/domain/usecases/upload_review_image_usecase.dart` | C1 — commerce usecase wiring | implemented-awaiting-final-verification |
| `frontend/lib/features/reviews/presentation/providers/review_providers.dart` | C1 — commerce provider wiring | implemented-awaiting-final-verification |
| `frontend/lib/shared/either/either.dart` | C2 — shared Either cleanup | implemented-awaiting-final-verification |
| `frontend/test/core/utils/currency_utils_test.dart` | C2 — shared regression test | implemented-awaiting-final-verification |
| `frontend/test/features/cart/cart_repository_test.dart` | C1 — commerce repository test | implemented-awaiting-final-verification |
| `frontend/test/features/orders/orders_page_test.dart` | C1 — commerce UI regression test | implemented-awaiting-final-verification |
| `frontend/test/features/reviews/review_repository_test.dart` | C1 — commerce repository test | implemented-awaiting-final-verification |
| `frontend/test/shared/either/either_test.dart` | C2 — shared Either test | implemented-awaiting-final-verification |
| `nest-backend/eslint.config.js` | B3 — lint/tooling gates | implemented-awaiting-final-verification |
| `nest-backend/src/modules/disputes/usecases/resolve-dispute.usecase.ts` | B2 — finance usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/payments/payments.controller.ts` | B2 — finance controller | implemented-awaiting-final-verification |
| `nest-backend/src/modules/payments/types/payment.types.ts` | B2 — finance finite event types | implemented-awaiting-final-verification |
| `nest-backend/src/modules/payments/usecases/expire-checkout-group.usecase.ts` | B2 — finance usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/payments/usecases/process-group-webhook.usecase.ts` | B2 — finance webhook usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/payments/usecases/process-webhook.usecase.ts` | B2 — finance webhook usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/domain/repositories/block.repository.ts` | B3 — users domain contract | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/domain/repositories/follow.repository.ts` | B3 — users domain contract | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/domain/repositories/user-lookup.repository.ts` | B3 — users domain contract | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/block-user.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/follow-user.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/get-block-status.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/get-follow-status.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/get-user-stats.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/index.ts` | B3 — users usecase wiring | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/list-followers.usecase.spec.ts` | B3 — users regression test | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/list-followers.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/list-following.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/unblock-user.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
| `nest-backend/src/modules/users/usecases/unfollow-user.usecase.ts` | B3 — users usecase | implemented-awaiting-final-verification |
