# Edit profile prefill regression (RED)

- Revision: `c9808b1` plus pre-existing dirty working-tree changes; this run added only `frontend/test/features/profile/edit_profile_page_test.dart` and this report.
- Environment: Flutter widget test with a local in-memory Dio adapter; no credentials, database, device, or backend. Fixture returns the authenticated owner's profile at `GET /users/me`.
- Observable contract: after mounting while the own-profile request is pending, the returned name, lowercase username, bio, city, state, and masked CPF are present in the edit form.
- Credible regression: the page reads `profileFutureProvider('me')` once in `initState`; if that read is loading, its `whenData` does not run when the request later completes. `build` watches the provider for loading/data UI but does not transfer arriving profile values into the controllers.
- Why current coverage misses it: existing profile widget tests cover timelines, sheets, and saved posts; none mounts `EditProfilePage` against delayed own-profile HTTP data.
- Test-only seam: none. Test uses `ProfileRepository` and the existing overridable provider with a local HTTP adapter.
- Scope: no assumptions about contact/name update windows or OTP contract; no production edits.

## Commands and outcomes

- `dart format test/features/profile/edit_profile_page_test.dart` — pass; formatted 0 changes on final invocation.
- `flutter analyze --fatal-infos test/features/profile/edit_profile_page_test.dart` — failed with one existing-in-test lint:
  ```
  info - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation - test\features\profile\edit_profile_page_test.dart:62:18 - prefer_const_constructors
  1 issue found. (ran in 4.9s)
  ```
- `flutter test test/features/profile/edit_profile_page_test.dart` — intended RED, 0 passed / 1 failed:
  ```
  Expected: exactly one matching candidate
    Actual: _TextWidgetFinder:<Found 0 widgets with text "Ada Example": []>
  #4      main.<anonymous closure> (file:///C:/Users/Qiyana/Documents/GitHub/ME/freebay/frontend/test/features/profile/edit_profile_page_test.dart:73:7)
  The test description was:
    prefills own profile fields when the HTTP profile arrives after mount
  00:13 +0 -1: Some tests failed.
  Exited with code 1
  ```

The test's first meaningful assertion fails after the HTTP-backed provider resolves, confirming the blank name field. Subsequent field assertions are not reached in this run. This RED is intended and must be made GREEN by the owning edit-profile implementation before it can serve as final regression coverage.

## Additional lifecycle checks (2026-10-02 resume)

Added distinct checks for (a) preserving a dirty form draft through a same-owner profile refresh and (b) preventing a late old-owner response from seeding or being saved for a newly authenticated owner. They use a controllable Dio HTTP adapter and an auth-controller subclass; no secure-storage/plugin calls or production seams are involved.

- `dart format test/features/profile/edit_profile_page_test.dart` — pass; 0 changes on resume run.
- `flutter analyze --fatal-infos test/features/profile/edit_profile_page_test.dart` — pass; `No issues found! (ran in 11.7s)`.
- `flutter test test/features/profile/edit_profile_page_test.dart --plain-name 'same-owner refresh does not replace an unsaved draft'` — failed before its draft oracle. Exact failure: `Expected: an object with length of <2> / Actual: [Instance of '_AsyncCompleter<ResponseBody>'] / Which: has length of <1>` at line 187. The controlled test did not observe a second GET after invalidation/refresh, so this does **not** establish whether the draft behavior is wrong; the refresh stimulus/provider lifecycle needs follow-up before treating it as an application regression.
- `flutter test test/features/profile/edit_profile_page_test.dart --plain-name 'late previous-owner profile cannot seed or save the new owner form'` — timed out after showing only the test file load line; no pass/failure assertion result. It is not valid evidence of the owner-isolation contract yet.

The original cold-prefill RED was not rerun. The two new lifecycle tests are not ready as adoption-ready checks until their widget/provider harness actually observes the intended HTTP request sequence; no conclusions about those behaviors are claimed from these runs.
