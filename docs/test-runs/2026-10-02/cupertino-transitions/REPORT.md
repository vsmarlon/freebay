# Cupertino route transitions

## Scope

`buildCupertinoPage` used `NoTransitionPage` when reduced motion was requested.
That bypassed the global `PageTransitionsTheme` and removed the native edge-pop
gesture. The route helper now uses a page-based Material route so the configured
theme owns the transition, while reduced-motion route durations are zero in both
directions. Story and highlight viewer pushes use the existing Cupertino route
helper. The five shell roots, auth transitions, and payment/deep-link navigation
were not changed.

## Verification

- Base revision: `81e8866d980e2783dfe29a53b8eb7ca088e727f5`; inherited working tree was dirty.
- Focused RED: `flutter test --no-pub test/core/router/cupertino_transitions_test.dart`
  exited 1 before the fix; normal iOS gesture passed and reduced-motion iOS edge
  swipe failed at the `router.canPop()` assertion (expected false, actual true).
- Focused GREEN: same command exited 0; both normal and reduced-motion iOS edge
  gestures popped to the visible feed page.
- Formatting: `dart format lib/core/router/route_helpers.dart lib/core/router/routes/social_routes.dart test/core/router/cupertino_transitions_test.dart`
  exited 0.
- Focused analysis: `flutter analyze --fatal-infos lib/core/router/route_helpers.dart lib/core/router/routes/social_routes.dart test/core/router/cupertino_transitions_test.dart`
  exited 0 with `No issues found!`.
- Product-list route: the `AppRoutes.products` additional route now uses the
  same Cupertino helper; all five shell-root registrations remain unchanged.
- Post-change focused run: `flutter test --no-pub test/core/router/cupertino_transitions_test.dart test/core/components/app_shell_test.dart test/core/router/app_router_test.dart`
  exited 0: 12 Cupertino transition cases, 8 shell cases, and 7 router cases
  (27 total).
- Physical Android/iOS validation was not performed.

## Remaining

Broader Flutter gates were deferred to the parent session after parallel source
owners stabilize; backend gates were already running there. No device/profile
validation is claimed.
