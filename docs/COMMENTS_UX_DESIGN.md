# Post conversations — X-inspired feature selection

**Date:** 2026-10-13. **Status:** owner selected all ten feature groups; exact behavior, optional items, and delivery phases are still being resolved.

Part of the [native UX and security design](NATIVE_UX_SECURITY_DESIGN.md). Read [feature truth](FEATURE_TRUTH.md) and [design tokens](../frontend/DESIGN.md) before implementation. The owner requested the full functionality menu before answering through the question tool.

## Current FreeBay boundary

| Capability | Current source evidence |
|---|---|
| Text, replies, likes | UI and backend paths exist. Replies store a parent comment ID; parent visibility and same-post membership are checked. |
| Conversation navigation | The detail page renders a nested comment tree. Arbitrary-depth retrieval, a focused reply screen, and comment deep links are not established. |
| Pagination/order | Repository reads oldest-first root comments, default 20, with limit/offset and included replies. The current page loads one collection; a complete paginated journey is not established. |
| Mentions/links/hashtags | Text highlighting and navigation exist. Backend mention IDs and notifications exist; the current composer does not establish a complete mention-selection journey. Close-friends comment mentions are explicitly rejected. |
| Deletion | Comment-delete endpoint exists; an owner delete action was not found in the inspected comment UI. |
| Restricted comments | Hidden/pending authorization and owner approval exist server-side. Current dirty UI includes approval handling, ahead of the historical feature-truth row; a complete device approval journey remains unverified. |
| Media and new social actions | Comment attachments, editing, reply-level repost/quote/bookmark, and comment-specific share routes were not found in the inspected contract. Post-level actions do not establish comment support. |
| Reliability | Duplicate-send UI guards and local count updates/refetch exist. Persistent per-target drafts, offline delivery, and new-reply live updates are not established. |

Source: [page](../frontend/lib/features/social/presentation/pages/post_details_page.dart), [comment item](../frontend/lib/features/social/presentation/widgets/comment_item.dart), [provider](../frontend/lib/features/social/presentation/providers/post_details_provider.dart), [repository](../nest-backend/src/modules/social/data/repositories/comment-database.repository.ts), [create use case](../nest-backend/src/modules/social/usecases/comment.usecase.ts), [write controller](../nest-backend/src/modules/social/social-write.controller.ts), [DTOs](../nest-backend/src/modules/social/dtos/social.dto.ts).

## Full selection menu

These are practical FreeBay options inspired by conversations on X. They are not a claim that every option is available in every X client or subscription.

### A. Conversation structure

- A1. Full-screen conversation with the original post and replies.
- A2. Tap a reply to focus it, with its parent/ancestor context and direct replies.
- A3. Reply to a reply; decide logical depth separately from visual indentation.
- A4. Expand/collapse branches and load more replies on demand.
- A5. Individual reply links that open and highlight the intended reply.
- A6. Continue one's own conversation through self-replies.
- A7. Preserve list position and focused reply when navigating back.

### B. Composer

- B1. Keyboard-safe persistent composer and optional expanded composer.
- B2. Explicit replying-to identity, parent preview, and cancel/change target.
- B3. Mention autocomplete with actual selected user identities.
- B4. Emoji, tappable hashtags, and safely opened links.
- B5. Character limit/counter and expandable long-text display.
- B6. Account- and target-scoped saved drafts with discard controls.
- B7. Optional link preview with privacy-aware fetching.

### C. Attachments

- C1. Images, including a decision on multiple-image limits.
- C2. Video with preview, upload progress, playback, and cancellation.
- C3. GIF selection or upload; external provider is a separate integration decision.
- C4. Media viewer, image alternative text, and accessible video captions.
- C5. Removal/replacement of attachments before sending.

### D. Reply-level social actions

- D1. Like/unlike with consistent counts.
- D2. Reply with a direct-reply count.
- D3. Repost/undo repost of an eligible reply.
- D4. Quote an eligible reply with commentary and original context.
- D5. Bookmark/unbookmark a reply.
- D6. Copy link, native sharing, and optional sharing into FreeBay chat.
- D7. Optional view/engagement counts; define privacy and counting semantics first.
- D8. Decide whether replies/reposts appear in feed and profile timelines.

### E. Reading and discovery

- E1. Oldest, newest, most-liked, or relevant reply ordering.
- E2. Original-author identification and optional author-reply prioritization.
- E3. Stable paginated loading, refresh, and duplicate-free results.
- E4. New-replies indicator without moving the reader's position.
- E5. Search within a conversation.
- E6. Optional translation and show-original control.

### F. Moderation and conversation controls

- F1. Author deletes their own reply; decide how descendant replies remain represented.
- F2. Report a reply with reason and confirmation.
- F3. Post author hides/unhides replies; define whether a hidden-replies view is public or restricted.
- F4. Complete the existing restricted-author pending/approval journey.
- F5. Block, mute, or restrict an author from the reply action menu.
- F6. Choose/change who may reply, or close the conversation to new replies.
- F7. Optional word filters and spam controls beyond the required server validation/rate limits.
- F8. Mute or leave conversation notifications, including unwanted mentions.

### G. Notifications

- G1. Notify the post author of a new eligible comment.
- G2. Notify the parent-reply author of a direct reply.
- G3. Notify valid mentions without leaking private or pending content.
- G4. Optional like/repost/quote notifications and notification preferences.
- G5. Follow/unfollow a conversation and open notifications at the exact reply.

### H. Sending and recovery

- H1. Optimistic pending/sent/failed states with retry and rollback.
- H2. Duplicate-safe submission and canonical server counts.
- H3. Restore drafts after navigation/restart; define offline drafts versus queued sending.
- H4. Optional pre-send undo delay, distinct from editing a published reply.
- H5. Handle deleted parents, changed reply permissions, and revoked audience access during submission.

### I. Fluid interaction and accessibility

- I1. Optional swipe-to-reply, long-press menu, and explicit button alternatives.
- I2. Native back behavior without stealing inner scrolling or shell gestures.
- I3. Text selection/copy, large-text layouts, labeled controls, and accessible focus order.
- I4. Reduced-motion support and consistent optional haptic feedback.
- I5. Measure long-thread scrolling and composer opening on the target device.
- I6. Localized controls and errors in the existing app locales.

### J. Explicit extensions, not assumed X parity

- J1. Edit a published reply, edited indicator, and optional revision history.
- J2. Pin/highlight a reply in a conversation.
- J3. Polls inside replies.
- J4. Voice replies or reactions beyond the like button.
- J5. Seller/buyer context or purchase eligibility controls; these are separate marketplace policy decisions.

## Required constraints for every selected feature

- A reply, its media, preview, notification, quote, or shared link must not widen the original content's audience. Preserve server authorization, blocks, restriction visibility, and account isolation.
- Preserve count/like atomicity, validate content and parent identity server-side, and protect retries from duplication.
- Loading, empty, failed, deleted, pending-moderation, and revoked-access states must be explicit and accessible.
- FreeBay's design tokens remain authoritative. X-inspired conversation behavior does not yet authorize replacing square geometry, typography, or tonal separation.
- Schema/API changes must be explicitly scoped; migrations remain owner-only under the hardening plan.

## Interview order

Select feature groups, then resolve reply identity/navigation, thread depth, ordering/pagination, selected action/media semantics, moderation and visibility, notifications/recovery, and delivery order. Ask one question at a time and record each accepted answer here.

## Accepted decisions

**C1 — Broad conversation scope:** the owner selected A through J: conversations, composer, attachments, social actions, reading/discovery, moderation, notifications, drafts/recovery, native interactions, and extra options. Each group's optional items and detailed semantics still require the next interview decisions; group selection is not a claim of implementation or approval of a migration/provider integration.

**C2 — Focused threads (owner accepted):** tapping a reply opens a full-width conversation centered on that reply, with its parent context and direct replies. Each reply has its own screen/link. Deep conversations do not become progressively narrower indented trees. Back restores the previous conversation and reading position. Feed/profile exposure and precise ordering remain separate decisions.

**C3 — Repost interaction (owner specified and clarified):** the quick-press/long-press rule applies to reposting, not to the comment composer. A quick press reposts immediately; a long press opens additional repost actions, including quoting with text, mentions, and attached pictures. Quoting creates commentary around the embedded original; commenting remains the ordinary reply flow. Preserve the existing ability to undo a repost. Extra actions also require an accessible, discoverable button/menu alternative to long press.

**C4 — X reply defaults delegated to the agent:** the owner clarified that comments should work like X and asked the agent to apply that established behavior. Use documented X conversation/reply semantics rather than asking the owner to re-specify standard interactions. C2 and the custom repost gesture in C3 remain explicit choices. Keep FreeBay's design tokens and existing audience protections. Features that differ from documented X behavior, such as editing published replies, remain unselected extensions despite inclusion of their catalogue group; do not silently treat every optional item as approved.

**C5 — Live privacy changes (owner accepted):** connected clients remove an affected private post conversation when access is revoked. Offline/reconnected clients revalidate before showing it again. See D5 in the [shared design](NATIVE_UX_SECURITY_DESIGN.md) for the story counterpart and transport decision.

**C6 — Full implementation scope (owner approved):** include the scoped Flutter, backend/API, Prisma model, and test changes required for the agreed features. Preserve existing comment IDs and client compatibility. Verify database behavior through the guarded test database; production migrations remain owner-run. This authorizes feature source/model work, not non-test database synchronization, migrations, or provider deployment.

**C7 — External GIF search and translation deferred (owner selected):** do not integrate either provider in this work. Use local image/video/GIF attachment selection and keep replies in their original language. This is an explicit scope choice, not an implementation blocker to hide behind a mock.

Implementation identity decision: [preserve reply identity and reference quote sources](adr/0003-preserve-reply-identity-and-quote-sources.md).

**Agent default under C4 — Reply exposure:** provide a privacy-filtered Replies view on author profiles and feed exposure through explicit reposts/quotes. Preserve existing feed ranking rather than claiming X's recommendation behavior. Automatic recommendation of otherwise unshared replies is not part of this default. This resolves the earlier unanswered distribution question using the owner's delegation of standard reply behavior; it is not a separately selected owner answer.

## X reference boundary

X describes replies as posts in a conversation and documents reply permissions, non-chronological ranking, and author hide/unhide. Its documented Edit post feature covers original/quote posts rather than replies; reply editing above is an explicit FreeBay extension. Premium Undo is a pre-publication delay, not an edit after publication. Poll/media availability and sorting options must not be inferred universally from original-post documentation.

References: [replies and mentions](https://help.x.com/en/using-x/mentions-and-replies), [conversations](https://help.x.com/en/using-x/x-conversations), [threads](https://help.x.com/en/using-x/create-a-thread), [Premium](https://help.x.com/en/using-x/x-premium), [glossary](https://help.x.com/en/resources/glossary). Research used official-help references and indexed results; direct parent-session fetches of the first two pages returned HTTP 403.

## Implementation contract (append-only; 2026-10-14)

This section freezes the additive API/model contract for implementation. It is design, not evidence of implementation. Existing `GET/POST /social/posts/:id/comments` and their oldest-first offset/flat response remain compatible; do not change legacy clients. Source confirms this route currently flattens roots plus shallow replies (`comment-database.repository.ts`), hidden pending comments use `isHidden`, and `CommentUseCase` currently creates comments/counts and sends mentions outside that transaction. New behavior is opt-in/additive.

### Routes and wire shapes

- `GET /social/posts/:id/conversation?limit=20&cursor=<opaque>&sort=recent|likes` returns `{items: CommentView[], nextCursor}`. Limits 1–50, default 20. Each item is a root plus direct replies (legacy flattened shape); roots are keyset-paged. `recent` uses `(createdAt DESC,id DESC)`. `likes` uses `(likesCount DESC,createdAt DESC,id DESC)`; concurrent likes can shift rows, so clients dedupe IDs and the API does not promise snapshot isolation. `GET /social/comments/:id/context?replyLimit=20&replyCursor=<opaque>&replySort=recent|likes&ancestorCursor=<opaque>` returns `{ancestors,focus,replies,nextReplyCursor,nextAncestorCursor}`. On the initial request, return the nearest at most 32 ancestors root-to-parent (oldest in this page through the immediate parent); `nextAncestorCursor` is opaque, or null when the root is reached. Supplying it requests the preceding at most 32 ancestors, also root-to-parent; prepend these client-side. Bind the cursor to focus comment and viewer-access scope; reject invalid or cross-focus cursors. Authorize every returned ancestor and never expose restricted-pending or otherwise hidden content. Deleted ancestors remain redacted tombstones. Loading ancestor pages merges by comment ID and must not reset the direct-reply cursor. Direct replies page by the same sort keys. Legacy shape/order remains unchanged.
- Create remains `POST /social/posts/:id/comments`; accept current DTO plus optional `clientRequestId` (UUID). Also accept `Idempotency-Key`; normalize either into one request key and reject if both differ. Persist `(userId,clientRequestId)` unique and a canonical payload hash. Same key/hash returns original canonical comment; same key/different hash is 409. The comment, mention rows, visible `Post.commentsCount` increment, and notification rows are one DB transaction. Restricted/pending creation has no public count or notifications until approved; retries must not repeat side effects. Notification socket/push delivery is post-commit best effort.
- `POST /social/comments/:id/repost`, `PATCH /social/comments/:id/unrepost`; unique `CommentShare(userId,commentId)`. Existing post share/unshare routes remain pure reposts. Existing feed stays legacy and omits comment reposts. Opt-in feed v2 represents an item as discriminated `{kind:'post'|'quote'|'comment_repost', id, ...}`; for comment repost, `id` is the `CommentShare.id` and nested target is `{commentId,postId}`—never place a comment ID in a post-ID field. Apply underlying post/comment authorization and block filters.
- `POST /social/quotes` accepts exactly one `sourcePostId` or `sourceCommentId`, commentary text, validated mention IDs, optional one image multipart field, and idempotency as above; returns `PostView` plus nullable `quoteSource` discriminator and source identity. Quote is a new `Post`; old `/share` does not become quote. Source must be visible, undeleted, unblocked, not restricted-pending/author-hidden at create and every render; if no longer eligible, omit/deny source content (do not reveal it through the quote). `SetNull` source deletion preserves the quote commentary without the source.
- `PUT /social/comments/:id/bookmark`, `DELETE` same, `GET /social/comments/bookmarks?limit=&cursor=`; unique `CommentBookmark(userId,commentId)`. Reuse existing saved-post privacy behavior; list filters inaccessible/deleted targets before pagination. `POST /social/comments/:id/report` accepts existing report reason contract; reporter must currently see the target, and cannot report a restricted-pending/hidden target through public endpoints. Add nullable `Report.reportedCommentId`, relation/index and unique `(reporterId,reportedCommentId)` for duplicate reports; preserve existing post reports.
- `PATCH /social/comments/:id/hide` and `/unhide` are post-author-only idempotent mutations of `authorHiddenAt`, separate from restricted moderation `isHidden`. `GET /social/posts/:id/hidden-replies?limit=20&cursor=` lists author-hidden replies (never restricted-pending `isHidden`) to viewers otherwise authorized for that post, under existing audience/block rules; no anonymous or unauthorized widening. Hidden replies are excluded from ordinary lists/counts; author and post owner retain context access. Approval never changes `authorHiddenAt`.
- Preserve soft-delete. Deleted parent with descendants is returned as a tombstone (stable id/parent path, author/content/media redacted, `deletedAt`, children still navigable); deleted leaf may be omitted. Decrement `commentsCount` only once and only if it was counted as visible; never cascade descendants. Pending/author-hidden rows do not affect public counts.
- `PUT /social/posts/:id/subscription` and `/mute` accept `{enabled:boolean}`; uniquely persist `CommentSubscription(userId,postId)` and `CommentConversationMute(userId,postId)`. Post author is implicitly subscribed unless muted. Subscriber fanout applies to visible comments with self/mute/block/privacy filtering. Mute suppresses mentions too but changes neither visibility nor global preferences.
- Notify post author, direct-parent author, validated mentions, and subscribed users for visible comments; dedupe IDs and suppress self, muted, blocked, ineligible recipients. Pending comments notify only after approval. Persist `commentId` and `data:{postId,commentId}`; add nullable `dedupeKey` with unique `(userId,dedupeKey)` because Notification currently has no event key. Comment key is `comment:<commentId>:<event>:<recipientId>`; existing rows leave it null. Create transactionally, deliver post-commit; opening routes to exact reply context.
- Feed opt-in: `GET /social/feed?version=2` (existing default omitted/version=1 unchanged) returns discriminated `{items:[{kind:"post",id,post}, {kind:"quote",id,post,quoteSource}, {kind:"comment_repost",id:commentShareId,postId,comment}] ,nextCursor}`. `post.id` is always Post.id; repost `id` is CommentShare.id and carries explicit commentId/postId. Profile `kind=replies` is additive; each item is `{kind:"reply",id:commentId,postId,comment,parentId,createdAt}` and uses existing cursor/limit (1–50), privacy filters before pagination. Apply visibility/block/pending/author-hidden predicates before cursor pagination and preserve existing mixed default and independent cursors. Do not auto-inject unshared replies into feed; feed v2 exposes only explicit comment reposts/quotes.

### Media and security

Comment create is same-request multipart `media` (0–4), each ≤20 MiB and request ≤20 MiB (route-specific cap, below the generic 25 MiB upload limit); use configured allowlist (JPEG/PNG/GIF/WebP, MP4/MOV/WebM), validate MIME and bytes, persist SHA-256 and private owner-bound `CommentMedia`. Quote permits one image ≤20 MiB. Authenticated reads recheck target access. Hash before write; rejected/failed transactions remove new objects. Claim unique idempotency key transactionally before media writes; concurrent same-key requests return canonical result, different digest is 409 and cleans loser files. No client URL ownership, external GIF search or translation.

On committed close-friends membership revocation, emit `private_content_invalidated` with exactly `{}` over existing authenticated `/notifications` Socket.IO connection. Derive recipients from committed membership/edge transitions (removed member; unfollow only when the last qualifying edge is gone; affected memberships on block); no-op/failed transactions emit nothing. Client evicts an open affected private story/conversation immediately, then refetches; reconnect and foreground revalidate before redisplay. Socket map is process-local: contract guarantees only connected clients on the serving process unless existing deployment adapter proves otherwise. Media authorization remains authoritative; already delivered bytes cannot be recalled.

### Schema additions and ownership

In `nest-backend/prisma/schema.prisma`: `Post.quoteSourcePostId/quoteSourceCommentId` nullable SetNull relations and query indexes; `Post.clientRequestId/clientRequestHash` and `Comment.clientRequestId/clientRequestHash` with unique `(userId,clientRequestId)`; `Comment.authorHiddenAt`; `CommentMedia`, `CommentBookmark`, `CommentShare`, `CommentSubscription`, `CommentConversationMute`; `Report.reportedCommentId` relation/index/nullable-safe uniqueness; `Notification.commentId` and matching uniqueness. Keep existing comment IDs/parent relations and deletion semantics. Add indexes only for these query paths. One backend owner owns this schema plus social DTO/types/controllers/repositories/use-cases and guarded DB verification; one Flutter owner owns routes/providers/repositories/UI/localizations/generated outputs. Do not concurrently edit shared contract files. Test DB use only guarded test configuration; no migration creation/execution and no non-test `db:sync`/seed. Production migration is owner-run.

### Required routine behavior / explicit exclusions

Implement the selected routine A–I scope: focused context/direct reply navigation and back-position restore; keyboard-safe composer, selected-user mentions, emoji/hashtags/safe links and limits; local image/video/GIF selection (max four, upload progress/cancel/remove); like/reply/repost/quote/bookmark/copy/native share; recent/likes cursors and refresh/dedupe; author hide, report, restricted approval UI, existing block/restrict affordances where already supported, follow/mute notifications; exact-reply notifications; optimistic pending/sent/failed with explicit retry/rollback, target-scoped persistent drafts, no silent offline auto-send; accessible gesture alternatives, localization, reduced motion, text scaling and shell/back/inner-scroll priority. Optional edit/history, pinning, polls, voice, extra reactions, external GIF/translation, ranking/relevance, and new fleet-wide socket architecture are out. Production migrations remain owner-only.

### Slices and gates

1. Baseline/reproduction owner: authenticated A30/profile VM and drawer red-capable timing before diagnosis; separate header, edge and content gesture, cold/warm. Story gesture tests before UI changes. Latest check: A30 `RX8M70JDTQV` (`SM_A305GT`) connected on launcher; API `:3000` health returns 200, but DB identity is unverified. No DTD app or profile VM is connected; this is blocked, not a baseline.
2. Backend contract/schema owner: frozen additive routes/models above; tests for visibility/blocks, idempotency digest conflict, transaction count+notification exactly-once, parent tombstone, concurrent keyset dedupe, private media cleanup/auth, quote source revocation; guarded test DB only.
3. Flutter conversation owner after contract freeze: navigation, composer/media/actions, profile Replies, v2 feed, drafts/retry, notifications, ARBs/codegen; focused widget/repository tests and accessibility/large text.
4. Revocation owner after backend and client seams: post-commit recipients, typed notification socket, connected eviction, reconnect/foreground revalidation and media-auth tests; two clients on one process only.
5. Integrate serialized DB/device/root/backend/Flutter gates; update feature truth only with new evidence. Production migration/deployment and multi-instance socket proof remain owner gates.

**C4 agent default for F6:** ordinary posts allow everyone to reply; provide routine controls for everyone, accounts the author follows, or mentioned accounts, plus explicit close-to-new-replies. Existing auth/block/privacy checks always apply. This is delegated X-like default, not a blocker. Hidden-replies listing obeys underlying post audience and block rules, never anonymous widening.

