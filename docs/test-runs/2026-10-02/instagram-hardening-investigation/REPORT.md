# Instagram-style hardening investigation — 2026-10-02

## Status

**Investigation / partial implementation tracked separately.** This report records source-traced findings and an ordered work scope; it does not certify completed fixes beyond the independently reported flash fix, a commit, or a device journey. The post-detail initial-loading fix and its focused test are recorded in [`post-initial-loading`](../post-initial-loading/REPORT.md). Focused RED → GREEN, sibling tests, analyzer, backend lint/tests and root CI results are in that report; current commit status is not established here.

## Provenance and constraints

- Branch: `feat/production-hardening`; starting HEAD: `81e8866`.
- The baseline working tree already contained 350+ dirty/untracked paths. Preserve them; do not stage unrelated files. A temporary baseline/evidence directory is at `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-20261002-instagram-investigation` and is not committed.
- No production/runtime database changes, migrations, or dependencies are authorized. `docs/FEATURE_TRUTH.md` was read but intentionally not edited because it is user-dirty.
- Device preflight only: Galaxy A30 / Android 11 (`SM-A305GT`) was online but locked. An older existing Flutter debug session was connected and was not restarted against this revision. Backend port 3000 had no listener; PostgreSQL 5432 and Redis 6379 were listening. No authenticated journey, gesture, pixel, upload, video-playback, or performance proof was obtained.
- A runtime diagnostic showed a historic shared-button text-scale overflow: `AppButton` row width 148, label width 154.1 at text scale 1.1 (`MELHORESAMIGOS`). This identifies a candidate shared component issue, not a reproduced current-device failure or a completed fix.

## Evidence map and remaining scope

| Order / area | Source-verified finding | Remaining task and acceptance boundary |
|---|---|---|
| 1. Media editor and stories | The editor exposes crop, brightness/contrast/saturation, seven filters, rotation/straighten, text, draw/marker/highlighter/eraser, undo/clear, preview, caption, chat, and view-once. Rotation controls change by ±π/2 while the slider permits `[-π, π]`; a supplied value `6.070761` lies outside the slider range. `TextOverlay` represents positioned/color/size text but does not establish editable on-canvas text layers. The native compositor adapter is `frontend/lib/features/media_editor/presentation/widgets/image_editor_compositor.dart`; input is capped at 32 MiB and output dimension at 2048, so source-resolution export is not promised. EXIF-orientation behavior across preview/crop/export is unverified; Android Exif and Swift ImageIO transforms exist. Stories (`CreateStoryPage`, `StoryPreviewView`, `StoryCanvas`) duplicate text controls/caption/audience while retaining image/video paths. | Correct angle normalization/slider synchronization and make text-layer behavior explicit/testable; validate EXIF, crop coordinates, rendering and output on both platforms. Keep existing native compositor contract; no dependency addition. Do not claim full gesture/pixel fidelity based on documentation for `pro_image_editor` (its defaults/capture path are not this implementation). Story/editor integration and device export remain unproven. |
| 2. Order cancellation sheet | `frontend/lib/features/orders/presentation/pages/order_detail_page.dart:330-458` starts cancellation with a direct pop then confirmation dialog; this is not a broken state-builder path. A non-scroll sheet can overflow. `showBrutalistSheet`/`BrutalistSheetScaffold` provide safe areas, insets and a 90%-height limit, but no fixed footer and no keyboard-height deduction. Backend cancellation of `PENDING`/`CONFIRMED` orders and current Stripe paths are existing behavior; DTO reason is a string persisted as `cancellationReason`. | Validate a scroll-safe, keyboard-aware reason sheet and preserve current confirmation and backend behavior. Refund, custody, tax, and release policy are unresolved owner decisions; do not implement or imply new financial rules without approval. |
| 3. Navigation/gestures | `app_theme.dart` already configures Cupertino and Android/iOS behavior. Chat/order/post/notification pushed routes use app Cupertino routes. Reduced-motion `NoTransitionPage` may affect gesture behavior; shell tab roots are intentionally excluded. | Audit custom auth/pages and `PopScope` selection in context, then exercise nested gestures and back behavior on device. Do not describe the whole app as lacking platform gestures or change shell roots indiscriminately. |
| 4. Chat replies | HTTP `send-message.usecase.toMessageOutput` (`226-243`) returns `replyToId` without nested `replyTo`; controller broadcasts that same summary (`141-159`). The socket-specific gateway helper (`249-279`) can look up and redact reply summaries. History includes nested summaries/redaction. Client optimistic send in `chat_conversation_actions.dart:60-69` omits nested reply, then confirmation replaces it with the summary-less HTTP response; bubble shows reply UI only when `replyTo` exists. Backend `assertReplyInThread` already enforces same-conversation authorization. Deleted originals can leave stale nested quote content; pagination-based jump returns early when target key is not loaded. Direct and order chat are separate; `order_detail_handleChat` starts a DM, not the order thread. No message-edit capability was found. | Align HTTP/socket/optimistic reply summaries without bypassing redaction; cover deleted/view-once reply privacy and unloaded-target pagination/jump with progress guard. Clarify/order-chat route separately; do not conflate DM and order thread or invent edit semantics. |
| 5. Account export | `GET /users/me/export` is currently rate-limited to 3/hour and returns allowlisted JSON; own messages are included by default. Profile privacy export shares JSON/text. No Bull/BullMQ/queue worker implementation or matching enqueue API was found in backend search; existing Redis is not evidence of a queue. A recent-auth signed timestamp guard exists for deletion cancellation and may be reusable if separately approved. Chat transcript endpoint already has authorization/pagination; client TXT export route was not found. | Async ZIP/CSV, category selection, reauthentication, signed-link expiry/delivery, audit events, and transcript client export are not established capabilities. Define scope, retention/privacy, and reauth policy before implementation; no legal-compliance claim. |
| 6. Video thumbnail dispatch | `media_grid.dart:138-175` and fullscreen dialog (`194`) use `Image.network` for raw attachments, including video. `chat_media_gallery_viewer.dart` extracts video (`19-27`) but uses `CachedNetworkImage` in main page (`114`) and strip (`170`). `StoryThumbnail` and `VideoMessageBubble` already use player-first-frame handling and are not the identified gap. | Dispatch typed image/video media and obtain a real poster/frame via existing authorized helpers/player/native facilities. Preserve auth headers, view-once and deleted-media behavior. No package addition; verify actual decode/playback on device. |
| 7. Error fallback | `main.dart` already registers global `FlutterError` and `PlatformDispatcher` handlers; `SentryErrorReporter` is configured when DSN exists. Crashlytics is not a dependency. `AppErrorWidget` exposes raw exception only in debug; release has a friendly fallback but no recovery action. | Keep safe fallback and add a back-safe retry only where the owning operation can actually be retried; do not promise a generic retry that cannot repeat the failed operation. Verify reporter behavior only with configured runtime evidence. |
| 8. Post detail initial loading | The provider initially returned a non-loading state and deferred load via microtask, allowing the missing-post predicate to render first. This is fixed/tested separately as recorded in [`post-initial-loading`](../post-initial-loading/REPORT.md). | Treat that report as the sole evidence for this slice. Its full Flutter suite/format remain red there; no device or profile proof. |
| 9. Shared bottom sheets | Existing `showBrutalistSheet` / `BrutalistSheetScaffold` are shared primitives with safe-area/inset handling and a 90%-height limit; current cancellation sheet has the separately noted content/keyboard limitations. | **Active planned, not implemented:** prioritize a focused global bottom-sheet behavior/quality pass, simplify or reuse existing shared patterns rather than duplicating implementations, and validate relevant callers, keyboard, large text, dismissal and gestures. No global behavior change or gate result is claimed. |
| 10. Error recovery | Global Flutter and platform error handlers and conditional Sentry reporting already exist; the release fallback does not provide an operation-aware recovery action. | **Active planned, not implemented:** improve global error recovery while preserving safe user-facing errors and back navigation. Add retry only when the failed operation is available to retry; no generic retry or telemetry delivery is claimed. |
| 11. Cupertino transitions | App theme configures Cupertino and Android/iOS behavior, and several pushed routes already use app Cupertino routes; reduced-motion no-transition pages may differ. | **Active planned, not implemented:** evaluate `CupertinoPageTransitionsBuilder` as the shared transition choice, preserve reduced-motion behavior and shell-root semantics, and audit route overrides before adoption. No transition change or device gesture proof is claimed. |

## Device and validation limits

No fresh app build/install/login was performed in this investigation. The A30 remained locked, so no app interaction is claimed; the backend had no listener on port 3000. The previous DTD connection is stale relative to this source state. Historical runtime errors and port/listener checks are diagnostic only; they are not current feature acceptance evidence. No native journey or full hardening gate is claimed here as passing. Flash regression evidence and its known gate results are linked in [`post-initial-loading`](../post-initial-loading/REPORT.md); that report records 1 intended RED / 1 GREEN, 4 sibling tests, analyzer pass, backend lint, 103 suites / 649 tests, and root CI pass. It also records full Flutter format exit 1 and suite result 288 passed / 5 failed (2 payment scaling, 2 edit-profile, 1 profile timeline). No native/runtime app journey was tested.

## Ordered follow-up and gate record

For each independently owned task, first capture its dirty-tree fingerprint and inspect all relevant callers; write a regression contract and intended RED before the fix; then run focused owner/sibling tests, applicable format/analyze/build or backend safety/integration gates, and device validation where the contract is visual/interactive. Record each exact command, exit status, revision, and blocker in this report or its owned task report. Commit only owned paths, one logical task per commit; the dirty baseline makes broad staging unsafe. The global bottom-sheet, error-recovery, and Cupertino transition work is active planned scope, not implemented. The gate/device commands below are proposed and **not run for those planned changes**:

```bash
# frontend (run from frontend)
dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib
flutter analyze --fatal-infos lib test libs/freebay_design_system/lib
flutter test
flutter build apk --debug

# backend (run from nest-backend only for a backend-owned change)
npx tsc --noEmit
npm run lint
npm test
npm run build
npm run test:safety
npm run test:integration
npm run test:e2e
```

Backend integration/E2E require the guarded test configuration and explicit PostgreSQL/Redis prerequisites; no production/runtime DB setup or migration. Device proof remains blocked pending an unlocked device, fresh app revision, and a defined authenticated fixture. Before any cancellation-flow financial behavior change, obtain owner decisions on refund/custody/tax/release policy. For commit isolation, do not claim ownership of pre-existing dirty editor/story files; coordinate their baseline ownership and stage only a verified task-specific path set.

## Export scope note

Opt-in category selection, including chat, is a product approach under consideration, not a legal-compliance certificate. LGPD Law 13.709/2018, Articles 18(II) and 19, addresses access/portability and complete access responses, including a 15-day declaration path. Any optional category controls must not be represented as replacing the complete-access request process or as permission to expose third-party data or raw secrets. [Official law text](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm), consulted 2026-10-02. This is not legal advice.

## Unvalidated risks

- Native editor output may differ from preview, especially for EXIF orientation, crop/rotation transforms, text and stroke placement, and size limits.
- Story creation may drift from editor behavior because controls are duplicated.
- Cancellation UX can still overflow with large text or keyboard; financial side effects/policy are intentionally unresolved.
- Reply summaries can be incomplete or retain stale private quote text; order-chat entry and unloaded-message jumps need dedicated journey validation.
- Export remains synchronous JSON with current default scope; no async/archive/download lifecycle is evidenced.
- Video-as-image surfaces may fail to render thumbnails; existing story/video-player paths do not prove galleries work.
- Release fallback has no operation-aware retry; configured telemetry delivery is unverified.
- Shared-button text scaling overflow remains a candidate from a historical diagnostic, not a verified current fix or device result.
