# Backend and CI final verification

**Date:** 2026-10-01  
**Branch / HEAD:** `feat/production-hardening` / `c9808b106c3d53f07837542e93f25fd52c6bfbe5`  
**Worktree:** dirty with concurrent UX work and other pre-existing user changes; no commit, branch change, or push.  
**Environment:** Windows, Node v24.10.0, Prisma CLI/client 7.4.2, local PostgreSQL `postgres` / `public` at `localhost:5432`. Credentials omitted.

## Runtime schema rollout proof

The runtime `.env` URL was checked in-process against `postgresql:`, host `localhost`, port `5432`, database `postgres`, and schema `public`, then queried before any write. The SQL result was `{"database":"postgres","schema":"public","address":"::1/128","port":5432}`. An initial version of the check rejected PostgreSQL's valid `::1/128` address formatting (exit 1); the corrected explicit local-address check passed before sync. No credentials were printed.

`npx prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --script` showed only:

```sql
ALTER TABLE "Post" ADD COLUMN "imageBlurHash" VARCHAR(166);
ALTER TABLE "ProductImage" ADD COLUMN "blurHash" VARCHAR(166);
ALTER TABLE "User" ADD COLUMN "avatarBlurHash" VARCHAR(166);
```

This exactly matched the three approved nullable fields. `npm run db:sync` completed with “Your database is now in sync with your Prisma schema.” The guarded post-check `npx prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --exit-code` returned “No difference detected.” A direct `information_schema.columns` query returned exactly those three columns, all `character varying(166)` and nullable. This is local development DB evidence only; no migration was created or run, and no production/staging DB was touched.

## Backend gates

Commands ran from `nest-backend`; each exited 0:

| Command | Result |
|---|---|
| `npx prisma generate` | Prisma Client v7.4.2 generated. |
| `npx tsc --noEmit` | Passed, no output. |
| `npm run lint` | Passed, zero warnings. |
| `npm test` | 99 suites passed; 614 tests passed. Jest emitted its existing warning that one worker was force-exited after tests; command exit 0. Expected error logging from failure-path tests appeared. |
| `npm run build` | Passed. |
| `npm run test:safety` | 5/5 guard tests passed. Expected refusal log for non-test environment. |
| `npm run test:integration` | Guarded `.env.test` sync targeted `freebay_test_db`; 18 suites / 102 tests passed. |
| `npm run test:e2e` | Guarded `.env.test` sync targeted `freebay_test_db`; 4 suites / 31 tests passed, including new cross-account media ownership tests and multipart BlurHash journeys. |

The test commands used the configured guarded test path only. The runtime `postgres` database was not seeded or used for tests.

## Root CI

Commands ran from repository root:

| Command | Result |
|---|---|
| `node scripts/ci-check.js` | Passed, exit 0. |
| `npm run test:ci-scripts` | Passed, 11/11 tests. |
| `git diff --check -- nest-backend scripts/ci-check.js scripts/ci-check.test.js` | Passed; Git emitted only line-ending conversion warnings for existing working-tree files. |

The first root CI run rejected pre-existing design-token findings after the stories and editor files moved paths. The findings corresponded to unchanged files present in the pre-move baseline, not new design debt. Added explicit current-path → baseline-path mappings for the moved story/editor files so existing findings retain their original baseline identity; the ratchet remains count-based and still rejects increases. The final root CI and script-test runs passed. `make test` was not run because it invokes Flutter analyzer/formatter/tests, which are owned by the parallel frontend finalization and were expressly out of scope here.

## Changed areas owned here

- Backend BlurHash schema, utility/upload and create/update/query response paths, privacy redaction, and associated HTTP/test DB assertions already present in the integrated worktree.
- `scripts/ci-check.js` and `scripts/ci-check.test.js`: preserve D1–D4 baseline identity for moved feature files without accepting extra occurrences.
- Local dev runtime DB schema synchronized only after identity query and exact-diff review above.

No migration, reset, seed, `--accept-data-loss`, force option, production DB access, or frontend command was used.

## Security review fixes — 2026-10-01

The reviewer found that create routes accepted client-chosen stored-media paths and then could remove those paths on later failure. Added HTTP + real-test-DB regression checks first: a second account copying a seller's product URL received **201** before the fix; reusing an owner's private-post URL also received **201**. After fixing, both receive **400** and `existsSync` confirms the original files remain. The avatar path is also exercised with the owner's uploaded avatar URL and confirms rejection plus file preservation.

The three owning client repositories now use their original same-request multipart APIs:

- `frontend/lib/features/product/data/repositories/product_repository.dart` → `POST /products` with `image`.
- `frontend/lib/features/profile/data/repositories/profile_repository.dart` → `POST /users/me/avatar` with `avatar`.
- `frontend/lib/features/social/data/repositories/social_repository_parts/social_repository_feed.dart` → `POST /social/posts` with `image`.

The corresponding controllers require the file generated for that request, compute BlurHash from those bytes, and are the only source of the create-route media URL/hash. DTOs no longer accept `images`/`imageUrl`/avatar URL or client BlurHash metadata; text-only social posts remain valid. Failure cleanup targets only the URL allocated from that request's uploaded file, and thrown failures are rethrown unchanged after cleanup. The generic upload API remains for callers such as chat; this change does not claim generic upload URLs have ownership binding.

After the source change: `npx tsc --noEmit`, `npm run lint`, `npm test` (99 suites / 614 tests), `npm run build`, `npm run test:safety` (5/5), `npm run test:integration` (18 suites / 102 tests), and the final `npm run test:e2e` (4 suites / 31 tests) all exited 0. Root `node scripts/ci-check.js` and `npm run test:ci-scripts` (11/11) also passed. Focused HTTP RED before the fix failed at the expected `201` vs `400` assertions; after the fix, the focused marketplace/story E2E selection passed 27/27, then full E2E passed 31/31. The focused run's first invocation also exposed test-fixture rate limiting while registering an extra actor; the regression now uses an already-registered stranger and the focused rerun produced the intended RED.

Frontend source edits are limited to the three repositories above (plus removal of now-unused repository imports); Flutter generation/analyzer/tests/build remain for the frontend finalization owner.
