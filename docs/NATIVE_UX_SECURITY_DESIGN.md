# Native-feeling UX and security — design interview

**Started:** 2026-10-13. **Status:** story/drawer behavior decisions accepted; comment feature contract frozen for implementation. No implementation or performance result is implied.

Read [feature truth](FEATURE_TRUTH.md), [hardening boundaries](HARDENING_PLAN.md), [existing UX plan](FRONTEND_UX_PLAN.md), [design tokens](../frontend/DESIGN.md), and [social vocabulary](../CONTEXT.md).

## Requested outcome

- Improve FreeBay security, measured performance, UI fluidity, and native-feeling gestures.
- Diagnose the lag when opening the feed drawer.
- Provide Instagram-like downward dismissal of stories while preserving browsing interactions.
- Expand post comments toward an X-style conversation experience. Scope and additive contract are recorded in the [comment design](COMMENTS_UX_DESIGN.md).
- Use Luna subagents for investigation and work through design decisions one question at a time.

These goals do not establish a completed fix or a measured performance improvement.

Comment feature inventory and subsequent choices: [Post conversations — X-inspired feature selection](COMMENTS_UX_DESIGN.md).

## Source-backed discovery

| Area | Current evidence | Next evidence needed |
|---|---|---|
| Story viewer | `story_viewer_page.dart` contains horizontal group paging, edge taps, pointer pause/resume, lifecycle pause, and a close action. It has no vertical drag-dismiss handler. Feed and highlight routes share this viewer. | Agreed dismissal contract, gesture regression coverage, and physical-device verification. |
| Feed drawer | `app_shell.dart` enables edge dragging and separately calls `openDrawer()` after the first branch's overswipe threshold. `feed_header.dart` also opens it. | Reproduce the reported lag separately for header tap, edge drag, and feed overswipe; distinguish first and repeated opens. These paths alone do not identify the cause. |
| Performance checks | The shell widget test checks opening. Existing performance flows omit drawer opening. | A drawer-specific, repeatable profile-mode measurement of input response and build/raster timings; feed-scroll results are not drawer results. |
| Security | Follow/block mutations do not consistently invalidate the viewer's story state; an open viewer retains its original groups. Fresh story lists and media requests are authorized by the backend. Session changes clear media caches. | Verify last-follow-edge removal against an already-open viewer, a refreshed list, and subsequent cache reuse. This is an unverified client privacy boundary, not a confirmed authorization bypass. Luna excluded its earlier conditional private-avatar concern. |

Source paths: [story viewer](../frontend/lib/features/stories/presentation/pages/story_viewer_page.dart), [story routes](../frontend/lib/core/router/routes/social_routes.dart), [shell](../frontend/lib/core/components/app_shell.dart), [feed header](../frontend/lib/features/social/presentation/widgets/feed_header.dart), [shell tests](../frontend/test/core/components/app_shell_test.dart), [performance runner](../scripts/perf-check.js).

## Accepted interaction decisions

**D1 — Interactive story dismissal (owner accepted):** during a deliberate downward drag, the story follows the finger and reveals the previous screen. Releasing early returns smoothly to the same story, preserving progress; a deliberate pull or fling closes and returns without losing the previous screen's position. Settling motion follows the existing design system, without overshoot.

**D2 — Content-wide vertical intent (owner accepted):** dismissal can begin anywhere on story content. Clear vertical intent is required; horizontal story navigation and visible control actions retain priority for their intended gestures.

Existing hold-to-pause and lifecycle pause remain required. D1's progress preservation means a canceled dismissal must not restart or advance the story. Playback settling details and accessible alternatives still need explicit acceptance criteria before implementation.

**D3 — Continuous feed-drawer reveal (owner accepted):** a rightward drag across ordinary feed content reveals the drawer progressively and can be canceled. Nested horizontal content retains its own gestures. Header-button opening remains an accessible alternative. This interaction change does not itself establish or fix the cause of runtime jank.

**D4 — Comment feature breadth (owner selected):** all ten groups in the [conversation catalogue](COMMENTS_UX_DESIGN.md) were included in the design interview. The implementation contract now freezes routine A–I behavior and exclusions; this is not blanket approval of every optional catalogue item.

**D5 — Live private-content revocation (owner accepted):** when Close Friends access is revoked, notify connected viewers so the affected open story or private post conversation is removed. Disconnected/offline clients must revalidate on reconnect/foreground and before redisplay. The owner delegated the transport choice and asked for a simple solution; first evaluate the existing Socket.IO facilities. This is a new client-lifecycle requirement, not evidence that live removal exists today. Events must not include private content or relax server-side authorization; already-delivered bytes cannot be retroactively withdrawn.

**D6 — Full feature implementation scope (owner approved):** scoped Flutter, backend/API, Prisma model, and test changes are included. Existing comment identities and clients remain compatible. Database verification uses the guarded test target; production migrations remain owner-run. See C6 in the comment design.


## Implementation sequence — under technical review

| Slice | Scope and owner boundary | Required evidence |
|---|---|---|
| 0. Reproduction | Establish an authenticated, representative A30 profile fixture using the approved test environment. Distinguish header tap, edge drag, and feed-content drag; first and repeated opens. | A red-capable drawer timing/frame loop before attributing a cause. Preserve source/device/build/fixture identity for comparison. |
| 1. Stories | Viewer gesture, route presentation, pause/settle lifecycle, and focused interaction tests. | Finger tracking, underlying screen visible, cancel preserves progress, horizontal/control priority, close alternative, reduced motion; physical story journey. |
| 2. Drawer | Shell gesture and drawer integration, after the measurement prerequisite. | Continuous reveal/cancel, unchanged tab identity, inner gesture priority, accessible open/close, equivalent before/after profile capture. |
| 3. Conversation contract | Single owner for Prisma, social DTOs/types/controllers/repositories, privacy/media rules, and compatibility. | Exact additive API/model contract, trusted upload ownership, request idempotency, correct counts, private/hidden/blocked/deleted handling, guarded HTTP/database checks. |
| 4. Conversation UI | Focused reply routes, composer/local attachments/mentions, actions, pagination, moderation, drafts/retry, notifications, and profile Replies. | Source-backed full journeys across new contracts; text scaling/semantics/keyboard/navigation; failed and offline submissions never silently send later. |
| 5. Live revocation | Targeted post-commit Socket.IO invalidation and client revalidation/visible-content removal. | Correct recipients for list removal, last-edge unfollow and block; failed/no-op writes emit nothing; connected-client and reconnect tests; media authorization remains separately checked. |
| 6. Integration | Serialized database/device checks, generated outputs, final review/security review, and feature-truth updates. | Exact focused/full gate outputs, source identity, device/performance evidence and explicit deployment/runtime limits. |

Parallel executors must have disjoint ownership. Stories and privacy share viewer lifecycle; drawer and privacy share shell foreground behavior; social contracts, Prisma, routes, localization and generated outputs each require a single coordinated owner. Run final gates after integration rather than while other workers rewrite their inputs.

**Technical review record:** first advisor review was followed by a second review (via general after a tool configuration error), which returned **REVISE** for one technical gap: the ancestor continuation beyond 32 had no named request/response fields. The conditional go was that backend and Flutter implementation may proceed once that contract is clarified. The comment design now specifies `ancestorCursor`, `ancestors`, and `nextAncestorCursor`, cursor binding/authorization, tombstones, and client merge behavior. This closes that condition; it is not a clean APPROVE verdict. The second review also confirmed the generic 25 MiB upload limit can accommodate the proposed route-specific 20 MiB comment cap and retained guardrails: preserve IDs/legacy behavior; test only against guarded `freebay_test_db`, with no migrations or non-test sync; socket delivery is single-process unless proven otherwise. No third review is required under the two-round limit.

A process-local Socket.IO map does not prove multi-instance delivery; deployment topology and shared delivery need explicit evidence.

## Decision records

The comment identity/quote trade-off is recorded in [ADR-0003](adr/0003-preserve-reply-identity-and-quote-sources.md). Keep reversible interaction choices here and domain definitions in the glossary.

## Current status correction — 2026-10-14

The comment breadth and delivery decisions below are no longer interview-pending: routine A–I behavior is delegated to documented X-like defaults, with optional extensions explicitly excluded in the [implementation contract](COMMENTS_UX_DESIGN.md#implementation-contract-append-only-2026-10-14). D4/C1 means all groups were interview scope, not blanket approval of optional items. The 2026-10-13 observation was an unauthenticated A30 login screen with no profile VM. Current check: `adb devices` is empty and API `:3000` is absent. No drawer latency baseline, causal diagnosis, performance improvement, or authenticated story/comment journey is established. The implementation contract is not implementation evidence. Production migrations remain owner-run; test database access is guarded only.
