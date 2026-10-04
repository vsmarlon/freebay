# Frontend UX finalization — owned UI slice

**Baseline revision:** `c9808b1`; working tree was already broadly dirty. Existing edits were preserved. This is not the final five-agent freeze report; full frontend gates remain with the coordinating session.

## Done in this slice

- Wired optional public-post image BlurHash and avatar BlurHash through `SocialPost` in the feed, post detail, and post search. Close-friends posts pass no image hash; their authenticated media path remains uncached.
- Wired profile avatar BlurHash into `UserAvatar` and product BlurHash through My Products, Cart, Purchases, Chat Product Picker, and favorites cards. All four requested surfaces use the real first product image's `ProductEntity.imageBlurHash`, cached network image, and existing media auth headers where applicable. BlurHash is omitted for private media URLs. `OrderEntity.product` is a `ProductEntity`, whose `images.first.blurHash` is exposed by that accessor.
- Replaced the social close-friends badge with existing `feedAudienceCloseFriends`, localized social timestamp with existing `localizedTimeAgo`, and standardized Favorites/Purchases back labels on `commonBack`.
- Left l10n ARBs untouched. Missing Favorites and Purchases page headings are listed with EN/PT-BR copy in `ui-localization-keys.json` for immediate ARB-owner integration.

## Verification

- `dart format` was run on the seven changed Dart files and formatted all seven.
- Targeted `dart analyze` exited 1 with six missing generated-l10n getters/methods: `profileFavoritesEmpty`, `profileStorySharePrompt`, `feedRepostedBy`, `feedLoginToSave`, `feedLoginToLike`, and `feedLoginToRepost`. Their ARB entries are present in the parallel tree; generated `AppLocalizations` appears stale. Codegen is intentionally deferred until the five-agent freeze. No compile pass is claimed.
- Full format/analyze/test/build are intentionally deferred until the five-agent freeze as instructed.
- No device or performance validation was performed.

## Remaining / reviewer

- Integrate the two heading keys in both ARBs, regenerate localization, and replace the source literals in Favorites/Purchases pages. Check the ARB owner has not already integrated these keys in parallel.
- Audit Hero pairing and route visibility for feed/detail and product result/detail; existing product grid suppresses duplicate entity tags. No Hero was added to the requested list thumbnails, since only My Products navigates to product detail and no source Hero is required here.
- Review these edits at the final freeze. Existing historical dirty files, including native platform work owned elsewhere, were not touched intentionally.
