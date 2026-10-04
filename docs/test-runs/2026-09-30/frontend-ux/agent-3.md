# Frontend UX hardening — executor 3

Date: 2026-09-30  
Working tree: shared multi-agent checkout; no commit created. Existing story-viewer user edits were left untouched.

## Completed across the initial and continuation passes

- `frontend/libs/freebay_design_system/lib/components/shimmer_skeleton.dart`: replaced one repeating ticker per skeleton block with a shared inherited animation scope. `SkeletonList` and `SkeletonPage` create a scope only when one is not already present; unscoped blocks render statically. `MediaQuery.disableAnimationsOf` suppresses the repeating controller. Shimmer surfaces use theme surface roles, with no border/separator.
- `frontend/libs/freebay_design_system/lib/tokens/app_theme.dart`: dark `ColorScheme.primary` maps to `AppColors.primaryForeground` (`#FF9DEE`); `primaryContainer` remains the `#8A1083` fill and `onPrimaryContainer` stays white on that fill.
- `frontend/libs/freebay_design_system/lib/tokens/app_colors.dart`: added the named `primaryForeground` token and mapped the dark hard-border token to it.
- `frontend/DESIGN.md`: updated the token authority wording for dark foreground/border and retained primary fill roles.
- `frontend/test/core/components/shimmer_scope_test.dart`: public observable ticker callback checks cover shared list ticking and static unscoped block.
- `BrutalistIconButton` now requires one semantic label, exposes an enabled/disabled button action, and retains at least a 48×48 hit target while preserving smaller visual chrome. All known app call sites were given contextual labels; duplicate wrapper announcements at auth/product headers were removed.
- Added `AppMotion.forContext` in the design token and applied it to route helpers. The shell pager/reduced-motion/connectivity changes are merge-agent-owned and were left untouched during this pass.
- Feed initial empty load now uses a single scoped three-card skeleton; refresh errors retain posts and show a retry snackbar. Orders preserve stale cached rows and show a non-blocking stale/refresh status. Empty saved-post and product-list failures now use retryable `EmptyState.error`; checkout product-load errors retry the actual provider.
- Public product/review images retain `CachedNetworkImage`, auth headers, sizes, placeholders, and errors. Product detail and the catalog grid/card use entity-based Hero tags; duplicate product IDs in one grid suppress Hero registration. Feed-post sources are restricted to feed/liked/saved routes and use the post ID; non-feed profile timelines suppress the source Hero. Shared `AppCardImage`, `UserAvatar`, `SocialPostMedia`, review avatars, and product detail now support BlurHash placeholders; product detail and catalog grid pass image hashes, review and product-seller avatars pass avatar hashes.
- Narrowed broad `MediaQuery.of` reads to `sizeOf`/`paddingOf` in chat/product widgets. Isolated the shell's full `MediaQueryData` copy in a `Builder`; keyboard insets and bottom padding remain intact.
- `profile_page.dart` now renders `profileFirstPaintProvider('me')`, so its own-profile header can show cached data immediately, keep it through refresh failure, and expose a live-region stale/error status. Manual refresh waits for a terminal fresh/error provider event; other profile IDs remain on the noncached provider.
- Added loaded-content text-scaling checks at 1.5×/2× for login, feed posts, product detail, checkout, and order detail; added product Hero duplicate-ID and inline product-list retry regressions. These feature tests await the final localization/codegen gate.
- `frontend/DESIGN.md` now documents reduced-motion role behavior. Dark role values are reflected in the table and code; all price amounts remain cents/display-value unchanged.

## Owned files touched

- Design system: `frontend/libs/freebay_design_system/lib/components/{brutalist_icon_button,shimmer_skeleton}.dart`, `frontend/libs/freebay_design_system/lib/tokens/{app_colors,app_motion,app_theme}.dart`, `frontend/DESIGN.md`.
- Shared owned components/routes: `frontend/lib/core/components/{app_card,app_card_image,user_avatar,user_list_tile}.dart`, `frontend/lib/core/components/social_post/post_media.dart`, `frontend/lib/core/router/route_helpers.dart`.
- Explicit page/widget ownership: `frontend/lib/features/reviews/presentation/widgets/review_card.dart`, `frontend/lib/features/social/presentation/{widgets/feed_post_item.dart,pages/feed_page.dart,pages/post_details_page.dart}`, `frontend/lib/features/profile/presentation/pages/profile_page.dart`, `frontend/lib/features/product/presentation/{pages/product_detail_page.dart,widgets/product_results_grid.dart}`.
- Tests/reports: `frontend/test/core/components/shimmer_scope_test.dart`, `frontend/test/features/{auth/login_text_scaling_test.dart,orders/order_detail_text_scaling_test.dart,payments/payment_page_test.dart,product/product_detail_text_scaling_test.dart,product/product_hero_tag_test.dart,product/product_load_more_error_test.dart,social/feed_post_list_loading_test.dart}`, `docs/test-runs/2026-09-30/frontend-ux/agent-3.md`.

## TDD and verification

Authoring gap: skeleton blocks previously each owned an independent repeating controller; no existing test proved one clock per skeleton composition or static rendering outside a scope. RED was observed before implementation:

```text
flutter test test/core/components/shimmer_scope_test.dart
Expected: <1>
Actual: <4>
...
Expected: <0>
Actual: <1>
```

After implementation, exact commands and results:

- Initial pass, before the continuation edits: `dart format libs/freebay_design_system/lib/tokens/app_theme.dart libs/freebay_design_system/lib/tokens/app_colors.dart libs/freebay_design_system/lib/components/shimmer_skeleton.dart test/core/components/shimmer_scope_test.dart` — formatted 2 files; exit 0.
- Initial pass, before the continuation tests: `flutter test test/core/components/shimmer_scope_test.dart` — 2 tests passed; exit 0.
- Initial pass, before later theme/button changes: `flutter analyze libs/freebay_design_system/lib/components/shimmer_skeleton.dart libs/freebay_design_system/lib/tokens/app_theme.dart libs/freebay_design_system/lib/tokens/app_colors.dart` — no issues found; exit 0. This is not a final analyzer result for the current tree.
- `flutter test test/core/components/shimmer_scope_test.dart --plain-name "icon button is exposed as an accessible button"` — 1 test passed; exit 0.
- `flutter test test/core/components/shimmer_scope_test.dart --plain-name "reduced motion disables the shared shimmer clock"` — 1 test passed; exit 0.
- `flutter test test/core/components/shimmer_scope_test.dart --plain-name "dark primary foreground and action fill keep separate roles"` — 1 test passed; exit 0.
- `flutter test test/core/components/shimmer_scope_test.dart` — all 6 tests passed; exit 0.
- During the preceding conflict-resolution window, feature test commands failed before assertions because the shared tree contained conflict markers. The integration coordinator later reported no unmerged paths. Examples from that historical compiler output:

```text
lib/core/components/app_shell.dart:186:1: Error: Expected an identifier, but got '<<'.
lib/features/social/data/repositories/social_repository_parts/social_repository_saves.dart:73:1: Error: Expected an identifier, but got '<<'.
lib/features/profile/presentation/providers/profile_timeline_provider.dart:53:1: Error: Expected an identifier, but got '<<'.
lib/features/profile/presentation/widgets/profile_tabs.dart:55:1: Error: Expected an identifier, but got '<<'.
```

`flutter test test/features/product/product_load_more_error_test.dart --plain-name "empty catalog error exposes an inline retry"` returned nonzero before assertions at that earlier revision because of source conflicts, including this verbatim diagnostic:

```text
lib/core/components/app_shell.dart:186:1: Error: Expected an identifier, but got '<<'.
lib/features/profile/presentation/providers/profile_timeline_provider.dart:53:1: Error: Expected an identifier, but got '<<'.
lib/features/profile/presentation/widgets/profile_tabs.dart:55:1: Error: Expected an identifier, but got '<<'.
lib/features/social/data/repositories/social_repository_parts/social_repository_saves.dart:73:1: Error: Expected an identifier, but got '<<'.
```

The same shared failures blocked the login/payment/feed feature runs at that earlier revision. Flutter test also ran dependency resolution and printed `Got dependencies!`; it did not complete those UX gates. The valid pre-change RED for shimmer is recorded above. A pre-change behavioral RED for icon semantics, Hero uniqueness, and feature layout could not be established; do not count compile-blocked runs as RED.

## Contrast evidence

WCAG relative-luminance contrast ratios, computed from the canonical token hex values. `#FF9DEE` is now the dark foreground/hard-border/accent; the deep magenta is deliberately a fill and not a text color.

The role is consumed through theme getters (not pasted hexes): `ColorScheme.primary`
backs linked/selected text in `brutalist_highlighted_text.dart`,
`message_bubble/expandable_text_message.dart`, `payment_view.dart`,
`product_preview_card.dart`, `category_selector_field.dart`, `app_card.dart`, and the
normal-state safe-link heading. `context.borderColor` maps to this same high-contrast
dark hard-border token across interactive frames. `AppColors.primaryContainer` remains
the action/selection fill; its text role is white `onPrimaryContainer`.

| Foreground / border | Dark canvas `#121212` | Card `#1C1C1C` | Elevated `#242424` | High `#2E2E2E` |
|---|---:|---:|---:|---:|
| `#FF9DEE` | 10.09:1 | 9.18:1 | 8.36:1 | 7.31:1 |
| `#F1F1F1` primary text | 16.59:1 | 15.09:1 | 13.74:1 | 12.02:1 |

| Fill treatment | Contrast |
|---|---:|
| White `#FFFFFF` on `#8A1083` primaryContainer | 8.46:1 |
| White `#FFFFFF` on `#660062` deep primary | 12.06:1 |
| `#8A1083` on dark canvas/card (not approved as foreground) | 2.21:1 / 2.01:1 |

## Localization and cross-owner handoff

The integration coordinator reports the conflict resolution complete. I did not modify merge-agent-owned `app_shell.dart`, `app_video_viewer.dart`, profile timeline files, social repository files, or the story-viewer test.

The following generated localization getters are referenced by the owned screens but are not present in the current catalogs. Agent 6 should add matching English and Brazilian Portuguese entries and regenerate l10n; this executor did not edit ARB files:

- `commonUnknownUser`, `reviewTypeBuyer`, `reviewTypeSeller`
- `feedRepostedBy(name)`, `feedLoginToLike`, `feedLoginToSave`, `feedLoginToRepost`, `feedLoginToShare`, `feedRefreshFailedShowingPosts`, `feedShareFailed`, `feedShareSuccess`, `feedReplyingHint`, `feedPostTitle`
- `productDetailTitle`, `productFavoriteAdd`, `productFavoriteRemove`, `productShareMessage(title, url)`, `productConditionNew`, `productConditionUsed`, `productSeller`, `productNoDescription`, `productForSaleBadge`
- `profileCacheRefreshing`, `profileCacheRefreshFailed`, `profileLoadError`, `profileSwitchToLight`, `profileSwitchToDark`

Blur-hash bridge handoff to agent 6 (owned intermediary UI): pass `post.imageBlurHash` through `core/components/social_post.dart` and `features/social/presentation/widgets/post_details_post_section.dart` into `SocialPostMedia`, and `post.user.avatarBlurHash` into its header; pass `user.avatarBlurHash` through `profile_avatar.dart`, `user_list_tile.dart`, and other avatar callsites; pass `ProductEntity.imageBlurHash` from `features/profile/presentation/pages/favorites_page.dart`, `features/product/presentation/pages/my_products_page.dart`, `features/product/presentation/pages/cart_page.dart`, `features/profile/presentation/pages/purchases_page.dart`, and the chat product-picker thumbnail into their image widgets. Add matching product Hero tags on Favorites/My Products item-to-detail navigations where IDs are unique; Cart/Purchases may retain image but are not source routes unless their tap opens product detail. These localized UI files were not edited here. `AppCardImage`, `UserAvatar`, review-avatar, product-detail, and catalog-grid surfaces consume hashes where the owned caller exposes metadata.

The existing `productCartLabel(count)` ARB value should be changed to plural-aware copy so count `1` does not announce “1 items.”

Agent 2 should include `avatarBlurHash` in the safe `profileFirstPaintProvider` cache serializer when the avatar URL passes the same public-URL guard; do not cache hashes alongside private/signed media URLs.

Private/revocable post/story and chat/view-once network branches remain deliberately uncached. The feed source Hero is enabled only on feed/liked/saved routes; the product grid suppresses tags for duplicate IDs. Profile timeline and other source routes do not use the shared post Hero until their route-specific duplicate behavior is handled by their UI owner. Device/perf checks were not run as requested.

Full codegen, format, analyzer, all feature tests, full Flutter suite, APK build, root CI gates, and device/perf verification remain for the final coordinated window after agent 6 supplies the listed keys and blur-hash bridge and the merge agent handoff is complete.
