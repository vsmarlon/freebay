# 2. Wall-clock session timeout

Date: 2026-09-07

## Status

Accepted

## Context

The app holds a wallet with real balances and escrow. Access tokens last 15
minutes and are refreshed silently; refresh tokens last 7 days. The only
existing expiry path was `HttpClient.onAuthLost`, which cleared tokens and
redirected to `/login` with no explanation — the user just found themselves on
the login screen.

The realistic risk is not a stolen token, it is an unlocked phone on a table
with the app open or in the background.

## Decision

Expire an authenticated session after **12 minutes of inactivity**, measured on
the **wall clock**, so time spent in the background and with the screen off
counts. `lastActiveAt` is persisted in `SharedPreferences`, refreshed by a
global `Listener(onPointerDown:)` in `main.dart`, and checked on
`AppLifecycleState.resumed`; a foreground `Timer` covers the app-open-and-idle
case. Because the timestamp is persisted, an app kill does not reset it.

12 minutes was chosen as the longest interval that still reads as "protected"
for a financial surface without interrupting an ordinary browsing session.

**One expiry path.** `SessionTimeout.onExpired` and `HttpClient.onAuthLost`
both call `_expireSession()`, which is guarded by an `_expiring` flag. An idle
timeout and a failed refresh landing together therefore raise one dialog, not
two. The dialog is a blocking `AppDialog.showError` with a single
"Fazer login" action, shown after the redirect.

Guests are skipped — `isAuthenticated()` returns false and nothing arms.

## Consequences

- A user who leaves the app for 20 minutes has to log in again. This is
  deliberate; biometric login makes it one tap.
- Anything that must survive a timeout has to be persisted before it, not held
  in provider state.
- The dialog is the only place the app explains a forced logout, so any future
  forced-logout trigger should route through `_expireSession()` rather than
  calling `forceLogout()` directly.
