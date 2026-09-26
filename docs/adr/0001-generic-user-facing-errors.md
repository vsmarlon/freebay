# 1. Generic user-facing errors

Date: 2026-09-07

## Status

Accepted

## Context

Raw exceptions were reaching users. Four mechanisms, all above the repository
layer. The current request boundary is `shared/http/request_either.dart`'s
`requestEither`, which maps Dio and decoder failures into `Failure` values:

- `AppErrorWidget` rendered `details.exception.toString()` full-screen in every
  build mode, so any uncaught build-phase error became a visible stack-ish dump.
- `mapDioExceptionToFailure` copied the backend's `error.message` into the
  `Failure` for 400/401/404/409/422, and ~40 sites render `failure.message`.
  A raw Prisma message on a `DB_ERROR` therefore reached the screen.
- 15 providers did `throw Exception(failure.message)`, and 14 widgets printed
  the result as `$err`.
- `main.dart` set neither `FlutterError.onError` nor
  `PlatformDispatcher.instance.onError`, so framework errors bypassed
  `runZonedGuarded`.

## Decision

**The client never renders a message the server wrote.**

The API already answers `{ success: false, error: { code, message } }` and
`shared/core/errors.ts` defines ~30 stable codes. The Flutter app switches on
the **code** and looks the copy up in `lib/shared/errors/error_messages.dart`;
the wire `message` is discarded. An unknown code falls back to a generic string
chosen by HTTP status.

Because `mapDioExceptionToFailure` is the only exception→`Failure` converter,
this makes `Failure.message` safe by construction — every existing
`failure.message` read is correct without being touched.

Two surfaces, chosen by what failed:

| Failure | Surface |
|---|---|
| An action (like, post, pay, withdraw, send) | `AppSnackbar` only; the screen stays as it was |
| Loading a whole page or list | Generic `EmptyState` + retry, so the user isn't left on a blank screen after a 3s snackbar |

Destructive actions use `AppSnackbar.undoable`: the UI removes the item
immediately and the DELETE only fires when the snackbar closes without UNDO.
No undelete endpoint exists, and none is needed for this.

Backend side, the same rule: the global filter sends a fixed
`'Erro interno do servidor'` for unexpected `Error`s (stack and message go to
the log), repositories pass fixed labels to `DatabaseError` instead of
`(e as Error).message`, and validation answers `'Dados inválidos.'` rather than
naming the fields that failed.

## Consequences

- Adding a backend error code means adding one line to `error_messages.dart`.
  Forgetting to is safe — the user sees the status-level generic.
- Debugging moves to Sentry and the server log, which now carry strictly more
  than before (`AppError.detail` holds what used to be interpolated into the
  user-visible message).
- Debug builds still show raw text in `AppErrorWidget`; release builds do not.
- `test/shared/errors/error_messages_test.dart` asserts that no status leaks the
  server's message. It is the regression that would silently undo all of this.
