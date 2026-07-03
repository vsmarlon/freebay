# Freebay (Flutter)

Flutter frontend for Freebay, a C2C marketplace app combining the social interactivity of Instagram with the escrow-backed transaction safety of Mercado Livre. Riverpod for state, Dio for HTTP, go_router for navigation.

## Getting Started

```bash
flutter pub get
flutter run                              # run on connected device/emulator
flutter test                             # all unit/widget tests
flutter test test/some_widget_test.dart  # single test file
flutter analyze                          # static analysis (must report zero issues)
flutter build apk --debug
```

See the root [CLAUDE.md](../CLAUDE.md) for the full Digital Brutalist design-system rules and the Clean Architecture conventions used across `lib/features/`.
