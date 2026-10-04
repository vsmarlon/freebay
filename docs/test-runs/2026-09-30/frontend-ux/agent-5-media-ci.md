# Executor 5 — BlurHash end-user path, D1–D4, move manifest

## Implemented source

- Backend generates BlurHash from uploaded image bytes using Sharp: EXIF rotation, max 32px decoding size, ensured RGBA, and the BlurHash encoder. Processing errors return no hash without failing or discarding the saved image. Private upload contexts skip encoding. `UploadController` now allows `product` and `privatepost` for the pre-upload clients; private media responses omit the hash.
- Persisted optional fields are `Post.imageBlurHash`, `ProductImage.blurHash`, and `User.avatarBlurHash`, each `String? @db.VarChar(166)`. No general Media table was introduced. Product/post/avatar direct multipart routes still compute server-side; the new Flutter clients pre-upload and pass `{url, blurHash?}` into the owning create/update DTOs.
- Public social create/feed/detail/search/saved/profile-timeline projections expose `imageBlurHash`; product create/list/detail/owner-list projections expose each image's `blurHash`; user profile/search/suggestions/follower/following/block responses expose `avatarBlurHash`. Posts for `CLOSE_FRIENDS` force the persisted hash to null and omit the response property, including query normalization even if an old row contains one. No DirectMessage/view-once field was added.
- `UploadService.uploadMedia(File, context)` returns `Either<Failure, UploadedMedia>` and safely parses optional/legacy metadata; `uploadFile` remains a URL-only adapter for existing chat callers. Social post, product-create, and avatar repositories use the typed path and send optional hash metadata to their API. Generated Freezed/JSON files are intentionally not hand-edited.
- Added `BlurHashPlaceholder` through `core/ui.dart`: validates BlurHash structure, renders the `flutter_blurhash` widget for valid hashes, and uses a caller-provided or theme-surface fallback for absent/malformed values. `flutter_blurhash: ^0.9.1` was added by executor 6, not edited here. The currently active image pages/widgets still require executor 3 to consume `PostEntity.imageBlurHash`, `ProductImageEntity.blurHash` / `ProductEntity.imageBlurHash`, and `UserEntity.avatarBlurHash`.
- The prior executor's D1–D4 design ratchet remains in place; `scripts/design-baseline.json` is still an untracked, sorted worktree artifact. It was scanned from pre-integration source commit `4558181`; current HEAD is `c9808b1`, with the parallel UX commits and further dirty changes after that snapshot. Snapshot scope is non-generated `frontend/lib/features/**/*.dart`. Findings: D1 **0**, D2 **240**, D3 **95**, D4 **215**, total **550**. It was not refreshed or shrink-updated in this continuation. Current post-merge drift has **not** been measured because CI gates were explicitly deferred; the final ratchet must reject all additions and report residual deltas rather than accepting them into baseline.
- Updated `docs/FEATURE_TRUTH.md` to state implementation versus runtime-proof limits.

## TDD / focused evidence

The RED tests were authored before the corresponding persistence/usecase changes:

1. HTTP + real guarded test DB public post create: original response lacked `imageBlurHash`. Command:

   ```text
   npx dotenv -e .env.test -- cross-env NODE_ENV=test jest --config jest.config.e2e.js --runInBand test/e2e/story-audience.e2e-spec.ts
   ```

   It exited 1 with **3 existing tests passing, 1 intended new test failing** at `typeof post.imageBlurHash`: expected `string`, received `undefined`. This ran before adding the schema columns and before the final code path; no schema sync was run by the direct command. The E2E was subsequently changed to exercise upload → JSON create → detail/feed.

2. Close-friends usecase redaction: `npx jest src/modules/social/usecases/social.usecase.spec.ts --runInBand` exited 1 with **11 passing, 1 intended test failing**. Exact relevant assertion output:

   ```text
   Expected: ObjectContaining {"audience": "CLOSE_FRIENDS", "imageBlurHash": null}
   Received: {"audience": "CLOSE_FRIENDS", "content": "Test content", "imageUrl": "/media/privatepost/123e4567-e89b-12d3-a456-426614174000.jpg", "type": "REGULAR", "user": {"connect": {"id": "user-123"}}}
   ```

3. Product and avatar E2E contracts initially failed on absent response metadata. Command:

   ```text
   npx dotenv -e .env.test -- cross-env NODE_ENV=test jest --config jest.config.e2e.js --runInBand test/e2e/marketplace.journey.e2e-spec.ts
   ```

   Exit 1: **19 passing, 2 intended new assertions failing**. Product create had `product.images` undefined; avatar response had `avatarBlurHash` undefined. These E2E cases were then adjusted to model the new upload → owning DTO path. They have **not** been rerun after schema changes.

4. Frontend model RED was exercised by temporarily restoring the pre-validation parser, then rerunning the owner test:

   ```text
   flutter test --no-pub test/shared/services/upload_service_test.dart
   ```

   It exited 1 specifically on malformed metadata while preserving the URL:

   ```text
   Expected: null
     Actual: 'not-a-blurhash'
   ```

   After restoring structural validation, the same exact command passed: **4 tests** (valid upload response, optional malformed hash, legacy response, missing/invalid URL).

5. `flutter test --no-pub test/core/components/blur_hash_placeholder_test.dart` passed: **2 tests** (valid hash renders `BlurHash`; missing/malformed values use the static fallback).

6. `npx jest src/modules/upload/upload.controller.spec.ts --runInBand` passed: **23 tests**, including real-image public generation and private omission. This is the current focused GREEN backend result.

An intermediate E2E invocation used `--config jest.config.e2e` (missing `.js`) and failed before test discovery:

```text
The --config option requires a JSON string literal, or a file path with one of these extensions: .js, .ts, .mjs, .cjs, .json.
```

An initial widget test imported the broad `core/ui.dart` barrel and hit concurrent checkout conflicts; it was narrowed to import the helper directly. A first fallback assertion counted both the Scaffold canvas and fallback `ColoredBox`; it was changed to assert a supplied fallback widget. The final focused widget test above passed.

## Current verification limits

- No Prisma client generation, schema sync, full tests, analyzer, build, formatter, integration suite, or full CI gate has been run in this continuation. These were explicitly reserved for the final phase. `schema.prisma` now requires a regenerated client before backend typecheck/unit/E2E can compile its new field selections.
- The E2E suite must run only through the guarded `.env.test` `npm run test:e2e`/`prisma:test:sync` path after final generation. No runtime `.env`, development DB, migration, or migration scaffold was touched. The new runtime DB columns and existing development DB drift remain unverified; production would need an owner-approved schema rollout before code uses these columns.
- The first widget-test attempt through the broad barrel hit active parallel merge artifacts, not a BlurHash assertion. Representative exact diagnostics:

  ```text
  lib/features/profile/presentation/pages/user_profile_page.dart:30:1: Error: Expected an identifier, but got '<<'.
  <<<<<<< Updated upstream
  lib/features/profile/presentation/providers/profile_timeline_provider.g.dart:61:1: Error: Expected a declaration, but got '<<'.
  lib/shared/l10n/app_localizations_context.dart:3:8: Error: Error when reading 'lib/shared/l10n/generated/app_localizations.dart': The system cannot find the path specified
  ```

  At the time of that test attempt, `git status` showed unresolved (`UU`) files owned by other executors; none were resolved or overwritten here. The latest status no longer shows `UU`, but `frontend/lib/shared/l10n/generated/app_localizations.dart` is still absent. The focused upload-model/helper test files are kept out of the feature/UI workstreams.
- Root CI ratchet tests/checks and `git diff --check` passed during executor 5's initial slice (see prior report history); the requested final gates are still pending.

## Final-only commands

After all owners freeze and resolve their own active conflicts:

```text
nest-backend: npx prisma generate
nest-backend: npm run tsc:check
nest-backend: npm run lint
nest-backend: npm test
nest-backend: npm run build
nest-backend: npm run test:safety
nest-backend: npm run test:integration
nest-backend: npm run test:e2e   # guarded .env.test database sync only
frontend:     dart run build_runner build --delete-conflicting-outputs
frontend:     flutter gen-l10n
frontend:     dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib
frontend:     flutter analyze --fatal-infos lib test libs/freebay_design_system/lib
frontend:     flutter test
frontend:     flutter build apk --debug
root:         node scripts/ci-check.js
root:         npm run test:ci-scripts
root:         make test
```

Do not run `npm run db:sync`, `npm run db:seed`, migration commands, or any `.env` runtime database push. Record actual exit codes and test DB schema evidence after those guarded final checks.

## Owner-approved LOCAL development DB rollout (prepared, not run)

The sanitized `.env` URL target currently parses as PostgreSQL `localhost:5432/postgres`, schema `public`; no username/password was printed. At the final instruction, prove the live connection identity before any change, using one real SQL statement through the app's `.env` runtime URL:

```powershell
npx dotenv -e .env -- node -e 'const {Client}=require("pg"); const u=new URL(process.env.DATABASE_URL); if(u.protocol!=="postgresql:" || u.hostname!=="localhost" || u.port!=="5432" || u.pathname!=="/postgres" || (u.searchParams.get("schema")||"public")!=="public") { console.error("DATABASE_URL does not match the approved local target"); process.exit(1); } const c=new Client({connectionString:u.toString()}); c.connect().then(()=>c.query("SELECT current_database() AS database, current_schema() AS schema, inet_server_addr()::text AS address, inet_server_port() AS port")).then(async r=>{const x=r.rows[0]; console.log(JSON.stringify(x)); await c.end(); if(x.database!=="postgres" || x.schema!=="public" || !["127.0.0.1","::1"].includes(x.address) || x.port!==5432) process.exitCode=1;}).catch(async()=>{try{await c.end();}catch{} console.error("Runtime database identity query failed; no sync authorized"); process.exitCode=1;});'
```

Then review, without applying, the SQL delta through the same configured datasource:

```powershell
npx prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --script
```

Only continue if the entire delta is the three approved nullable `VARCHAR(166)` fields (`Post.imageBlurHash`, `ProductImage.blurHash`, `User.avatarBlurHash`), with no unrelated drift or loss warning. If not, stop and report the actual diff. If it is exactly those fields, the owner-approved local sync is `npm run db:sync` (the existing `prisma db push && prisma generate` script; no `--accept-data-loss`, `--force-reset`, direct SQL, or migration). Verify afterward with:

```powershell
npx prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --exit-code
```

Expected post-sync exit is 0. This local `postgres` target is distinct from guarded `freebay_test_db`; test DB sync remains only through `npm run test:e2e` / `npm run test:integration`. No such command has been run in this continuation.

## Deferred exact frontend move manifest — execute after owners freeze

No source move happened: executor 3 is editing feed/social/profile UI and executor 4 owns the editor plus Android/iOS compositor. These are real bounded slices, but moving them during active edits would overwrite live work. Move each file and its references/tests together; update routes and imports to the new public boundary; do not leave compatibility aliases.

### Stories: `features/social` → `features/stories`

Move the story data/repository boundary and story presentation as one feature slice:

- `frontend/lib/features/social/data/entities/story_entity.dart` and generated `story_entity.freezed.dart` / `story_entity.g.dart`.
- `frontend/lib/features/social/data/repositories/social_repository_parts/social_repository_stories.dart` into a concrete `features/stories/data/repositories/stories_repository.dart` (extract the existing API implementation from the `part of SocialRepository` arrangement; do not wrap/export the old social repository as a permanent alias).
- `frontend/lib/features/social/presentation/controllers/story_submission_coordinator.dart`.
- `frontend/lib/features/social/presentation/providers/story_highlight_provider.dart`; separate story feed state/API currently consumed by `feed_provider.dart` into the Stories owner.
- `frontend/lib/features/social/presentation/pages/create_story_page.dart`, `my_stories_page.dart`, `story_viewer_page.dart`, `story_viewer_wrapper.dart`.
- `frontend/lib/features/social/presentation/widgets/story_canvas.dart`, `story_capture_view.dart`, `story_highlight_editor.dart`, `story_highlights_section.dart`, `story_page.dart`, `story_preview_view.dart`, `story_text_styles.dart`, `story_thumbnail.dart`, and `stories_row.dart`.
- Update `feed_page.dart`/`feed_provider.dart` call sites to consume the Stories feature's public rail/API; update route builders and paths currently targeting those pages; migrate story/highlight tests from `test/features/social/` to `test/features/stories/` while preserving their actual assertions.

### Image editor/media composition: `features/chat` → `features/media_editor`

Move the editor as a standalone local-media editing feature, not the native compositor implementation:

- `frontend/lib/features/chat/presentation/pages/image_editor_page.dart`.
- `frontend/lib/features/chat/presentation/widgets/image_editor_models.dart`, `image_editor_paint.dart`, `image_editor_toolbar.dart`, `image_editor_views.dart`, `image_editor_compositor.dart`, `color_filters.dart`, and `draw_palette.dart` if the frozen import graph confirms editor-only callers.
- Replace the editor route with `features/media_editor`'s public route/page API. Update `chat_media_composer.dart` and `create_story_page.dart` consumers to that public API; do not move either consumer's chat/story upload or action logic.
- Keep `frontend/android/app/src/main/kotlin/com/freebay/app/NativeImageCompositor.kt`, `frontend/android/app/src/main/kotlin/com/freebay/app/MainActivity.kt`, `frontend/ios/Runner/NativeImageCompositor.swift`, `frontend/ios/Runner/AppDelegate.swift`, and platform project registration where they are. Executor 4 owns those files; the moved Dart feature consumes their established channel through an owned adapter.
- Move/update image editor behavioral tests to `test/features/media_editor/`; update router tests and all imports in the same move. No Android/iOS file is to be touched during this executor's active phase.

The final move must first re-inventory the post-freeze dependency graph and current routes/tests, then execute these slices with targeted RED → GREEN evidence; this manifest is not a completion claim.

## Left for reviewer / owner gates

- Have executor 3 wire the helper into cached public image widgets and pass through entity fields. Keep missing/malformed hashes on existing static placeholders and do not render close-friends or view-once hash metadata.
- Review schema rollout/runtime behavior; only the guarded test DB was used for prior RED checks, and no runtime schema operation is authorized here.
- `sharp` declares Node `>=20.9.0`; confirm the deployed Node runtime.
- Backend dependency install previously reported 58 npm audit findings (2 low, 26 moderate, 29 high, 1 critical). No automatic audit fix was run.
