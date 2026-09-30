# UX2 social backend verification

## Revision and environment

- Base revision: `455818164b7b87e5d57eb1dd84313eacd9ce580b`.
- Social changes: `685e849` (privacy) and `7160c30` (timeline API).
- Final test-fixture and evidence changes are in the follow-up commit(s) containing this report.
- Environment: Windows, NestJS E2E app over HTTP, PostgreSQL `localhost:5432/freebay_test_db`, schema `public`; Prisma schema sync reported already in sync. No credentials recorded.
- Test process: serial only; this worktree was the sole E2E runner using the destructive shared test DB.
- Reset/fixtures: each `npm run test:e2e` invocation runs guarded `prisma:test:sync` (`NODE_ENV=test`, localhost `freebay_test_db` only). The suite's `cleanDatabase` truncates test tables before/after its suite. The four auth users are registered through the real HTTP endpoint. The connection-transition case clears only its owner/member follow, close-friend, and block rows, then creates deterministic real-DB edges; post/story publication, reads, media fetches, follow/unfollow, block/unblock, and membership edits stay over HTTP.

## RED evidence

The original full-suite failure was the default short throttle bucket for the `GET /stories` handler: `THROTTLE_SHORT_LIMIT` defaults to 10 with a one-second TTL, keyed by handler, bucket name, and `req.ip`. Separate test cases reused the same test IP, so their repeated story-feed reads accumulated in one bucket. The four fixture registrations were below `/auth/register`'s separate five-per-minute limit. This was test-client state, not an intended social rejection. Captured response:

```text
GET /stories returned 429: {"success":false,"error":{"code":"INTERNAL_SERVER_ERROR","message":"ThrottlerException: Too Many Requests"},"requestId":null,"timestamp":"2026-09-30T05:40:31.644Z","path":"/stories"}
```

No production throttling setting was changed, no 429 was accepted, and no behavioral assertion was weakened. The test app now trusts forwarded addresses only from loopback and assigns each independent test case a distinct reserved TEST-NET client IP. This gives each journey a fresh real per-client throttler bucket while keeping the production guard enabled and exercising it through HTTP.

The privacy regression's pre-fix RED was also reproduced against the old follower-only candidate/add predicates (temporarily restored in the worktree, then reverted):

```text
Expected: ArrayContaining ["1695cc7c-9275-4f03-8e03-abe8e7175662", "eb060669-0659-4341-b8c4-c02c547b53cc"]
Received: ["1695cc7c-9275-4f03-8e03-abe8e7175662"]
Test Suites: 1 failed, 1 total
Tests:       1 failed, 3 skipped, 4 total
```

The failure was the owner-following-only candidate missing from the real HTTP response, not a compile error or limiter response. The updated privacy implementation then passed the unchanged audience assertions.

## GREEN commands and results

All E2E invocations below were run serially, with the guarded test DB sync printed as already in sync.

1. `cd nest-backend; npm run test:e2e -- --runTestsByPath test/e2e/story-audience.e2e-spec.ts`
   - Exit 0. **4/4 tests passed**, including current story/highlight/media access, comments privacy, private-post discovery and media revocation, both connection directions, final-edge removal, block/unblock, and no implicit restoration after refollow.
2. `cd nest-backend; npm run test:e2e -- --runTestsByPath test/e2e/marketplace.journey.e2e-spec.ts -t "registers a seller and a buyer|paginates own posts and reposts together|filters the profile timeline by event kind before paginating"`
   - Exit 0. **3/3 selected tests passed**. The existing mixed timeline/default-cursor journey remains intact; posts/reposts/products filtering, type-specific cursors, later-page results, and invalid-kind rejection pass.
3. `cd nest-backend; npx tsc --noEmit`
   - Exit 0, no diagnostics.
4. `cd nest-backend; npx eslint test/e2e/story-audience.e2e-spec.ts --max-warnings 0`
   - Exit 0, no diagnostics.
5. `git diff --check`
   - Exit 0.

Detailed command output is in [`verification.log`](verification.log). The story E2E emitted an existing `pg@9` deprecation warning about `client.query()` on an already executing query; it did not affect the result.

## Remaining scope

Full backend unit/integration/build gates and device verification were not run; they are outside this focused UX2 phase. The frontend client was not changed here.
