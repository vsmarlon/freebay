# Freebay (Flutter)

Flutter frontend for Freebay, a C2C marketplace app combining the social interactivity of Instagram with the escrow-backed transaction safety of Mercado Livre. Riverpod for state, Dio for HTTP, go_router for navigation.

## Getting Started

```bash
flutter pub get
flutter run                              # run on connected device/emulator
flutter test --dart-define=API_BASE_URL=http://127.0.0.1:43187  # isolated unit/widget tests
flutter test test/some_widget_test.dart  # single test file
flutter analyze                          # static analysis (must report zero issues)
flutter build apk --debug
```

The test gate uses this dedicated loopback origin so auth lifecycle tests exercise the default notification WebSocket without contacting a backend. `--dart-define` values are embedded in the build; never use them to conceal secrets.

## Local development (USB / LAN)

From the repository root, `npm run dev:profile` is the default physical-device
run; `npm run dev:debug` starts Debug mode. Both perform USB selection, restore
`adb reverse` for port 3000, and wait for the FreeBay API identity plus database
and Redis readiness before launching Flutter. Choose an attached device with
`FREEBAY_ADB_DEVICE=<serial>` or `npm run dev:profile -- --device <serial>` when
more than one is connected. A failed USB setup stops with a non-zero exit.

Use LAN values from this app's existing `.env` without rewriting it with
`npm run dev:profile -- --transport lan` (or `dev:debug`). USB alone overrides
`API_BASE_URL` to `http://localhost:3000`; the override is applied after
`--dart-define-from-file=.env`. Existing HTTPS release configuration is not
changed. `make run-profile DEVICE=<serial>` and `make run-debug DEVICE=<serial>`
delegate to the same scripts.

VS Code's first launch is **FreeBay App (USB Profile — default)**. Set
`FREEBAY_ADB_DEVICE` in the VS Code process environment to choose explicitly;
with multiple attached devices and no selector, setup fails before Flutter
launch. The post-debug task stops only its setup runner and any backend it
started; reused services stay up. LAN Debug/Profile launch entries continue
using `.env`. Profile runs are AOT and require a new run to apply code changes;
use Debug for iteration.

See the root [CLAUDE.md](../CLAUDE.md) for the full Digital Brutalist design-system rules and the Clean Architecture conventions used across `lib/features/`.
