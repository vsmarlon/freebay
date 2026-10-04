# Store-compliance frontend slice

**Revision:** `c9808b1` plus the existing dirty working tree and this frontend slice.  
**Environment:** Windows; Flutter/Dart on the local SDK. API, Stripe, Apple, Google, and legal-link credentials were not used. No device or live payment was exercised.

## Implemented

- Replaced the native mobile PaymentSheet/Card entry points in single-order and cart checkout with `flutter_stripe`'s official `PlatformPayButton` and `confirmPlatformPayPaymentIntent`. The existing web Stripe Checkout session links are unchanged. Wallet completion still says payment is pending; order settlement remains webhook-owned.
- Wallet confirmation uses integer cents; Apple Pay summary amount formats cents without floating-point conversion. `BRL` mirrors the current backend invariant in `create-payment-intent.usecase.ts`, `create-payment-session.usecase.ts`, `checkout-cart-payment.ts`, and the two webhook handlers. No backend/payment API was changed.
- Wallet controls fail closed unless Stripe is configured and `PAYMENT_MERCHANT_COUNTRY_CODE` is a two-letter uppercase code. iOS also requires `APPLE_PAY_MERCHANT_ID`. Android requires explicit `GOOGLE_PAY_TEST_ENV=true` outside release; release requires `GOOGLE_PAY_PRODUCTION_ENABLED=true` and test mode off. The Android Google Pay metadata and iOS Apple Pay entitlement templates are present.
- Added a Privacy & Data profile settings route: data export through the existing `GET /users/me/export`, explicit deletion confirmation, 30-day pending/deletion-blocker/financial-retention copy, session/cache cleanup on successful request, and cancellation only through the existing authenticated endpoint. The own-user response's existing `deletionRequestedAt` is decoded. Privacy, terms, and deletion legal actions resolve against the configured API origin using the agreed paths; no publish URLs or support contact were invented.
- Added a localized user-profile report action using the existing `POST /reports` `USER` target contract and valid report reasons. Existing block affordances remain unchanged.
- Added only the approved exact `sign_in_with_apple: 8.2.0` dependency and Apple sign-in entitlement. **Apple sign-in UI/authentication is not implemented**: the required Apple nonce flow needs SHA-256 of the secure raw nonce, and the approved dependency does not provide hashing. Adding a direct crypto dependency or custom cryptographic implementation would exceed the explicit dependency approval, so this slice is stopped pending approval of a SHA-256 implementation/dependency.

## Verification

- `flutter pub get` — exited 0; installed `sign_in_with_apple 8.2.0` and its platform packages. Existing lock constraints were not deliberately upgraded.
- `flutter gen-l10n` — exited 0. It reports the existing `pt` fallback catalog as untranslated (now 993 keys); `pt_BR` and English entries were added and generated successfully.
- `dart run build_runner build --delete-conflicting-outputs` — exited 0; generated the `UserEntity.deletionRequestedAt` serialization. The installed build_runner reports that the CLI flag has been removed/ignored.
- Focused tests: `flutter test test/features/payments/payment_view_test.dart test/features/cart/cart_checkout_page_test.dart test/features/profile/profile_privacy_repository_test.dart test/features/profile/privacy_page_test.dart` — passed (all 9 tests).
- `flutter analyze --fatal-infos` on all changed Dart implementation and test files — `No issues found!`.
- `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib` — `Formatted 609 files (0 changed)`.
- `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` — `No issues found! (ran in 14.3s)`.
- `flutter test` — failed: 285 passed and the existing dirty `test/features/profile/follow_state_test.dart` case `FollowStateNotifier & followStatusProvider does not seed a status after its account session changes` failed. Re-running `flutter test test/features/profile/follow_state_test.dart` reproduced it. Exact failure:

  ```text
  Expected: <2>
    Actual: <3>
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\profile\follow_state_test.dart 411:7  main.<fn>.<fn>
  ```

  This test file was not changed by this slice; its failure is left untouched.
- `flutter build apk --debug` — exited 0; produced `build/app/outputs/flutter-apk/app-debug.apk`. Gradle emitted the existing Kotlin Gradle Plugin migration warning for Sentry/Stripe.
- Payment source scan: `grep` for PaymentSheet/card-copy tokens under `frontend/lib/features/cart` and `frontend/lib/features/payments` returned no matches.
- No iOS build, device wallet presentation, Apple/Google merchant verification, account-deletion HTTP/device journey, or production settlement was tested. The Android APK build proves compilation only.

## Test notes and limits

The existing checkout widget tests asserted the old PaymentSheet/Card button. After switching the UI, those assertions failed because the old button was absent; they now assert the localized fail-closed wallet-unavailable state when no wallet config/device is present. This was not a pre-edit RED run. The new privacy repository and confirmation/logout tests were added after implementation and pass; they do not prove backend or provider behavior.

## Owner configuration and remaining work

- Set `PAYMENT_MERCHANT_COUNTRY_CODE` to the actual platform merchant country; no value is baked in.
- Set `APPLE_PAY_MERCHANT_ID` through Dart defines and provide the same merchant ID as an Xcode build setting for entitlement expansion; configure Apple Developer capability, team, and provisioning profile.
- Set `GOOGLE_PAY_TEST_ENV=true` explicitly in test builds. Enable release only after merchant approval by setting `GOOGLE_PAY_PRODUCTION_ENABLED=true` and leaving Google Pay test mode off.
- Approve a SHA-256 dependency/implementation before completing Sign in with Apple. The backend executor owns `/auth/apple` and the server-side account contract; no client email/subject trust or implicit account linking was added here.
- Public legal pages and account-deletion content still need owner-published values/content. The app uses the approved paths but does not claim those pages are live.
- No backend, schema, migration, live provider, or production legal configuration was changed by this frontend work.
