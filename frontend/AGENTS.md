# Frontend guidance

Follow the repository-root `../AGENTS.md` and its required skills. This file records frontend-specific decisions only:

- Use Flutter's generated `AppLocalizations` for visible user-facing copy; English and Brazilian Portuguese ARBs live in `lib/shared/l10n/`. Resolve strings via `l10n(context)` from `shared/l10n/app_localizations_context.dart`. Keep protocol values, IDs, logs, and backend contracts untranslated.
- Follow `DESIGN.md` for UI tokens and the `freebay-flutter-feature` / `freebay-design-system` skills for feature changes.
- New shared/server state uses Riverpod code generation (`@riverpod`); prefer `AsyncNotifier` for mutable async state and generated `FutureProvider` for read-only async values. Do not add new `StateProvider` or `StateNotifier`. When modifying one, migrate it to the appropriate generated provider unless a documented compatibility constraint prevents it; leave untouched legacy providers alone. Use `setState` only for ephemeral, widget-local interactions. Watch providers in build, read in callbacks, listen for side effects, and select only needed fields.
- Export cross-feature APIs from their owning feature boundary; do not import another feature's presentation internals.
